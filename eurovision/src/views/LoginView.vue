<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useChatNotifications } from '../composables/useChatNotifications'

const { initializeNotifications } = useChatNotifications()

const name = ref('')
const email = ref('')
const inviteCode = ref('')
const error = ref(null)
const router = useRouter()

const handleLogin = async () => {
  error.value = null

  // check if email is whitelisted
    const { data: whitelist, error: whiteListError } = await supabase
      .from('email_whitelist')
      .select('*')
      .eq('email', email.value)
      .single()

    if (whiteListError) {
      error.value = 'Access denied: your email is not authorized.'
      return
    }

  const password = email.value // consistent password

  // First, try to sign up
  let { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email: email.value,
    password,
    options: {
      data: {
        full_name: name.value.trim(), // This will be used by the trigger
      },
    },
  })

  let user = signUpData?.user

  // If user already exists, sign in instead
  if (!user && signUpError?.message.includes('User already registered')) {
    console.log('User exists, signing in...')
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password,
    })

    if (signInError) {
      error.value = signInError.message
      return
    }
    user = signInData.user
  }

  if (!user) {
    error.value = 'Authentication failed.'
    return
  }

  // For existing users, update their name if it's different
  if (signUpError?.message.includes('User already registered')) {
    const { error: updateError } = await supabase
      .from('users')
      .update({ name: name.value.trim() })
      .eq('id', user.id)

    if (updateError) {
      console.warn('Could not update user name:', updateError.message)
    }
  }

  // Use the helper function to join the group
  const { data: joinResult, error: joinError } = await supabase.rpc('join_group_with_invite_code', {
    invite_code_param: inviteCode.value.trim(),
  })

  if (joinError || !joinResult?.success) {
    error.value = joinResult?.error || 'Invalid room code or failed to join group.'
    return
  }

  // Initialize chat subscription with the group ID
  initializeNotifications()
  // push to home when signup or sign in is successfull
  router.push('/home')
}
</script>

<template>
  <main>
    <img src="/pwa-512x512.png" />
    <h1>Join a Room</h1>
    <form @submit.prevent="handleLogin">
      <input v-model="name" type="text" placeholder="Your name" required />
      <input v-model="email" type="email" placeholder="Email" required />
      <input
        v-model="inviteCode"
        type="text"
        placeholder="Room code"
        required
        autocapitalize="none"
        spellcheck="false"
        autocomplete="off"
      />
      <button type="submit">Join Room</button>
    </form>
    <p v-if="error">{{ error }}</p>
  </main>
</template>

<style scoped>
form {
  display: flex;
  flex-direction: column;
}
input {
  font-size: 16px;
}
input[type='text'],
input[type='email'] {
  width: 100%;
  padding: 12px 20px;
  margin: 8px 0;
  box-sizing: border-box;
}
h1 {
  text-align: center;
}
img {
  width: 70%;
  display: block;
  margin: 0 auto;
}
</style>
