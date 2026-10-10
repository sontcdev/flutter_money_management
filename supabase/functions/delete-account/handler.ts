export type WorkspaceBlocker = {
  workspace_id: string;
  workspace_name: string;
};

export interface DeletionGateway {
  verifyUser(token: string): Promise<string | null>;
  prepare(userId: string): Promise<{
    status: 'prepared' | 'blocked';
    workspaces?: WorkspaceBlocker[];
  }>;
  objects(userId: string, offset: number, limit: number): Promise<{
    bucket_id: string;
    name: string;
  }[]>;
  remove(bucket: string, names: string[]): Promise<void>;
  deleteUser(userId: string): Promise<void>;
}

export function createDeletionHandler(gateway: DeletionGateway) {
  return async (request: Request): Promise<Response> => {
    const headers = {
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
    };
    const respond = (status: number, body: unknown) =>
      Response.json(body, { status, headers });
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers });
    }
    if (request.method !== 'POST') {
      return respond(405, { code: 'method_not_allowed' });
    }
    const authorization = request.headers.get('authorization');
    const token = authorization?.match(/^Bearer (\S+)$/i)?.[1];
    if (!token) return respond(401, { code: 'unauthorized' });
    try {
      const userId = await gateway.verifyUser(token);
      if (!userId) return respond(401, { code: 'unauthorized' });
      const result = await gateway.prepare(userId);
      if (result.status === 'blocked') {
        return respond(409, {
          code: 'shared_workspace_membership',
          workspaces: result.workspaces ?? [],
        });
      }
      if (result.status !== 'prepared') throw new Error('Invalid preparation');
      const pageSize = 200;
      for (let offset = 0; ; offset += pageSize) {
        const objects = await gateway.objects(userId, offset, pageSize);
        const buckets = new Map<string, string[]>();
        for (const object of objects) {
          const names = buckets.get(object.bucket_id) ?? [];
          names.push(object.name);
          buckets.set(object.bucket_id, names);
        }
        for (const [bucket, names] of buckets) {
          await gateway.remove(bucket, names);
        }
        if (objects.length < pageSize) break;
      }
      await gateway.deleteUser(userId);
      return respond(200, { status: 'deleted' });
    } catch {
      return respond(500, { code: 'account_deletion_failed' });
    }
  };
}
