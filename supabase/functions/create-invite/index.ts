// supabase/functions/create-invite/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

console.log(`Function "create-invite" up and running!`)

serve(async (req) => {
  // Обробка CORS preflight запиту
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  
  try {
    const { wallet_id } = await req.json()
    if (!wallet_id) {
      throw new Error('Wallet ID is required in the request body.')
    }

    // Створюємо клієнт Supabase з правами користувача, який викликав функцію
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Отримуємо поточного користувача
    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'User not authenticated' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // --- ОСНОВНЕ ВИПРАВЛЕННЯ ТУТ ---
    // Перевіряємо, чи має користувач право створювати запрошення для ЦЬОГО гаманця.
    // Цей запит правильно порівнює uuid з uuid та integer з integer.
    const { data: permission, error: permissionError } = await supabaseClient
      .from('wallet_users')
      .select('role')
      .eq('user_id', user.id)       // Порівнюємо UUID з UUID
      .eq('wallet_id', wallet_id) // Порівнюємо Integer з Integer
      .single()

    if (permissionError) throw permissionError
    
    if (!permission || (permission.role !== 'owner' && permission.role !== 'editor')) {
      return new Response(JSON.stringify({ error: 'Insufficient permissions' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403,
      })
    }
    
    // Якщо права є, створюємо запрошення
    const { data: invite, error: inviteError } = await supabaseClient
      .from('wallet_invites')
      .insert({ wallet_id: wallet_id, created_by: user.id })
      .select('token')
      .single()

    if (inviteError) throw inviteError

    // Повертаємо токен на клієнт
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