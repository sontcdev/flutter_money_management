import { createClient } from 'npm:@supabase/supabase-js@2.117.3';
import { createDeletionHandler, type WorkspaceBlocker } from './handler.ts';

const url = Deno.env.get('SUPABASE_URL');
const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!url || !key) throw new Error('Missing server configuration');
const client = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(createDeletionHandler({
  async verifyUser(token) {
    const { data, error } = await client.auth.getUser(token);
    if (error) return null;
    return data.user?.id ?? null;
  },
  async prepare(userId) {
    const { data, error } = await client.rpc('prepare_account_deletion', {
      p_user_id: userId,
    });
    if (error) throw error;
    if (data?.status !== 'prepared' && data?.status !== 'blocked') {
      throw new Error('Invalid preparation response');
    }
    return data as {
      status: 'prepared' | 'blocked';
      workspaces?: WorkspaceBlocker[];
    };
  },
  async objects(userId, offset, limit) {
    const { data, error } = await client.from('account_deletion_objects')
      .select('bucket_id,name').eq('user_id', userId)
      .order('bucket_id').order('name').range(offset, offset + limit - 1);
    if (error) throw error;
    return data;
  },
  async remove(bucket, names) {
    const { error } = await client.storage.from(bucket).remove(names);
    if (error) throw error;
  },
  async deleteUser(userId) {
    const { error } = await client.auth.admin.deleteUser(userId, false);
    if (error) throw error;
  },
}));
