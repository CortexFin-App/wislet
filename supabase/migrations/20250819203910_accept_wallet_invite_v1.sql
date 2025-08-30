create or replace function public.accept_wallet_invite_v1(
  p_token uuid,
  p_user_id uuid,
  p_user_email text
)
returns void
language sql
as $$
  select public.accept_wallet_invite(
    p_token      => p_token,
    p_user_id    => p_user_id,
    p_user_email => p_user_email
  );
$$;
