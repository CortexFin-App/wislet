import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  
  try {
    const body = await req.json()
    const walletId = parseInt(body.wallet_id, 10)
    
    if (isNaN(walletId)) {
      throw new Error('Invalid Wallet ID format. Expected an integer.')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      throw new Error('User not authenticated');
    }

    const { data: permission, error: permissionError } = await supabaseClient
      .from('wallet_users')
      .select('role')
      .eq('user_id', user.id)
      .eq('wallet_id', walletId)
      .single()

    if (permissionError) throw permissionError
    
    if (!permission || (permission.role !== 'owner' && permission.role !== 'editor')) {
      throw new Error('Insufficient permissions');
    }
    
    const { data: invite, error: inviteError } = await supabaseClient
      .from('wallet_invites')
      .insert({ wallet_id: walletId, created_by: user.id })
      .select('token')
      .single()

    if (inviteError) throw inviteError

    return new Response(JSON.stringify({ invite_token: invite.token }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})