import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { createDeletionHandler, type DeletionGateway } from './handler.ts';

function fixture() {
  const calls: string[] = [];
  const gateway: DeletionGateway = {
    async verifyUser(token) { calls.push(`verify:${token}`); return 'caller'; },
    async prepare(id) { calls.push(`prepare:${id}`); return { status: 'prepared' }; },
    async objects(id, offset) {
      calls.push(`objects:${id}:${offset}`);
      return [{ bucket_id: 'receipts', name: 'own.jpg' }];
    },
    async remove(bucket, names) { calls.push(`remove:${bucket}:${names.join(',')}`); },
    async deleteUser(id) { calls.push(`delete:${id}`); },
  };
  const request = new Request('https://example.invalid/delete-account', {
    method: 'POST', headers: { authorization: 'Bearer test-token' },
    body: JSON.stringify({ user_id: 'victim' }),
  });
  return { calls, gateway, request };
}

test('verified caller is deleted only after its storage cleanup', async () => {
  const { calls, gateway, request } = fixture();
  assert.equal((await createDeletionHandler(gateway)(request)).status, 200);
  assert.deepEqual(calls, ['verify:test-token', 'prepare:caller',
    'objects:caller:0', 'remove:receipts:own.jpg', 'delete:caller']);
});

test('shared workspaces block all cleanup', async () => {
  const { calls, gateway, request } = fixture();
  gateway.prepare = async () => ({ status: 'blocked', workspaces: [
    { workspace_id: 'shared', workspace_name: 'Family' },
  ] });
  const response = await createDeletionHandler(gateway)(request);
  assert.equal(response.status, 409);
  assert.equal((await response.json()).code, 'shared_workspace_membership');
  assert.deepEqual(calls, ['verify:test-token']);
});

test('storage failure leaves Auth user available for retry', async () => {
  const { calls, gateway, request } = fixture();
  gateway.remove = async () => { throw new Error('private diagnostic'); };
  const response = await createDeletionHandler(gateway)(request);
  assert.equal(response.status, 500);
  assert.equal((await response.json()).code, 'account_deletion_failed');
  assert.equal(calls.some(call => call.startsWith('delete:')), false);
});

test('missing and invalid JWT cannot prepare deletion', async () => {
  const { calls, gateway, request } = fixture();
  gateway.verifyUser = async () => null;
  assert.equal((await createDeletionHandler(gateway)(request)).status, 401);
  assert.equal((await createDeletionHandler(gateway)(new Request(request.url, {
    method: 'POST',
  }))).status, 401);
  assert.deepEqual(calls, []);
});

test('browser preflight does not authenticate or delete', async () => {
  const { calls, gateway, request } = fixture();
  const response = await createDeletionHandler(gateway)(new Request(request.url, {
    method: 'OPTIONS', headers: { origin: 'https://app.example.invalid' },
  }));
  assert.equal(response.status, 204);
  assert.equal(response.headers.get('access-control-allow-origin'), '*');
  assert.match(response.headers.get('access-control-allow-headers')!, /authorization/);
  assert.deepEqual(calls, []);
});

test('cleanup pages are stable and group removals by bucket', async () => {
  const { calls, gateway, request } = fixture();
  gateway.objects = async (id, offset, limit) => {
    assert.equal(id, 'caller');
    assert.equal(limit, 200);
    calls.push(`page:${offset}`);
    if (offset === 0) return Array.from({ length: 200 }, (_, n) => ({
      bucket_id: n < 100 ? 'first' : 'second', name: `file-${n}`,
    }));
    return [{ bucket_id: 'third', name: 'last' }];
  };
  gateway.remove = async (bucket, names) => {
    calls.push(`batch:${bucket}:${names.length}`);
  };
  const response = await createDeletionHandler(gateway)(request);
  assert.equal(response.status, 200);
  assert.deepEqual(calls, ['verify:test-token', 'prepare:caller', 'page:0',
    'batch:first:100', 'batch:second:100', 'page:200', 'batch:third:1', 'delete:caller']);
});

test('Auth failure reports failure instead of deletion success', async () => {
  const { gateway, request } = fixture();
  gateway.deleteUser = async () => { throw new Error('Auth unavailable'); };
  const response = await createDeletionHandler(gateway)(request);
  assert.equal(response.status, 500);
  assert.deepEqual(await response.json(), { code: 'account_deletion_failed' });
});
