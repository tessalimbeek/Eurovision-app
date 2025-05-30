<template>
  <main>
    <div class="max-w-md mx-auto p-4">
      <h1 class="text-2xl font-bold mb-6">Your Profile</h1>

      <div class="top">
        <div class="profile-picture">
          <input
            type="file"
            accept="image/*"
            ref="fileInput"
            @change="uploadAvatar"
            style="display: none"
          />
          <img :src="avatarUrl || defaultAvatar" alt="Profile Picture" class="profile" />
          <button @click="triggerFileSelect" class="change">Change</button>
        </div>

        <h1>{{ name }}</h1>
      </div>

      <p v-if="uploading" class="text-sm text-blue-500">Uploading...</p>
      <p v-if="uploadError" class="text-sm text-red-500">{{ uploadError }}</p>

      <form @submit.prevent="updateProfile" class="mb-8">
        <label for="name">Name</label>
        <input id="name" v-model="draftName" type="text" required />
        <button type="submit" :disabled="updating">
          {{ updating ? 'Saving...' : 'Save Changes' }}
        </button>
        <p v-if="updateError" class="text-red-500 mt-2">{{ updateError }}</p>
        <p v-if="updateSuccess" class="text-green-500 mt-2">Profile updated successfully!</p>
      </form>

      <h2 class="text-xl font-semibold mb-4">Group Members</h2>
      <ul v-if="groupMembers.length > 0">
        <li v-for="member in groupMembers" :key="member.id" class="group-member">
          <img :src="member.avatar_url || defaultAvatar" alt="Member avatar" class="avatar" />
          <div class="member-name">{{ member.name }}</div>
        </li>
      </ul>
      <p v-else class="text-gray-500">You're not in any group yet.</p>
    </div>
  </main>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'

const name = ref('')
const draftName = ref('')
const avatarUrl = ref('')
const defaultAvatar = '/default-avatar.png'
const uploading = ref(false)
const uploadError = ref(null)
const updating = ref(false)
const updateError = ref(null)
const updateSuccess = ref(false)
const groupMembers = ref([])
const fileInput = ref(null)

const triggerFileSelect = () => {
  fileInput.value?.click()
}

const generateSignedUrl = async (filePath) => {
  if (!filePath) return null

  try {
    const { data: signedUrlData, error: signedUrlError } = await supabase.storage
      .from('avatars')
      .createSignedUrl(filePath, 60 * 60) // 1 hour valid

    if (signedUrlError || !signedUrlData?.signedUrl) {
      console.warn('Failed to generate signed URL:', signedUrlError)
      return null
    }

    return signedUrlData.signedUrl
  } catch (error) {
    console.error('Error generating signed URL:', error)
    return null
  }
}

const uploadAvatar = async (e) => {
  const file = e.target.files[0]
  if (!file) return

  uploading.value = true
  uploadError.value = null

  try {
    const { data: authData, error: authError } = await supabase.auth.getUser()
    const user = authData?.user

    if (authError || !user) {
      uploadError.value = 'User not authenticated.'
      return
    }

    const filePath = `${user.id}/${Date.now()}_${file.name}`

    // Upload the file to the private bucket
    const { error: uploadErr } = await supabase.storage
      .from('avatars')
      .upload(filePath, file, { upsert: true })

    if (uploadErr) {
      uploadError.value = 'Failed to upload avatar.'
      return
    }

    // Update user record with relative path
    const { error: updateErr } = await supabase
      .from('users')
      .update({ avatar_url: filePath })
      .eq('id', user.id)

    if (updateErr) {
      uploadError.value = updateErr.message
      return
    }

    // Generate a signed URL for displaying the image
    const signedUrl = await generateSignedUrl(filePath)
    avatarUrl.value = signedUrl || defaultAvatar
  } catch (error) {
    console.error('Upload error:', error)
    uploadError.value = 'An error occurred during upload.'
  } finally {
    uploading.value = false
  }
}

const updateProfile = async () => {
  updating.value = true
  updateError.value = null
  updateSuccess.value = false

  try {
    const { data: authData, error: authError } = await supabase.auth.getUser()
    const user = authData?.user

    if (authError || !user) {
      updateError.value = 'User not authenticated.'
      return
    }

    const { error } = await supabase
      .from('users')
      .update({ name: draftName.value })
      .eq('id', user.id)

    if (error) {
      updateError.value = error.message
    } else {
      name.value = draftName.value
      updateSuccess.value = true
      // Clear success message after 3 seconds
      setTimeout(() => {
        updateSuccess.value = false
      }, 3000)
    }
  } catch (error) {
    console.error('Update error:', error)
    updateError.value = 'An error occurred while updating.'
  } finally {
    updating.value = false
  }
}

const fetchGroupMembers = async (groupId) => {
  if (!groupId) {
    groupMembers.value = []
    return
  }

  try {
    const { data: members, error: memberError } = await supabase
      .from('users')
      .select('id, name, avatar_url')
      .eq('group_id', groupId)

    if (memberError) {
      console.error('Error fetching group members:', memberError)
      return
    }

    // Process member avatars
    const processedMembers = await Promise.all(
      members.map(async (member) => {
        if (member.avatar_url) {
          const signedUrl = await generateSignedUrl(member.avatar_url)
          return { ...member, avatar_url: signedUrl || defaultAvatar }
        } else {
          return { ...member, avatar_url: defaultAvatar }
        }
      }),
    )

    groupMembers.value = processedMembers
  } catch (error) {
    console.error('Error processing group members:', error)
  }
}

const fetchProfile = async () => {
  try {
    const { data: authData, error: authError } = await supabase.auth.getUser()
    const user = authData?.user

    if (authError || !user) {
      console.error('User not authenticated:', authError)
      return
    }

    const { data: profile, error: profileError } = await supabase
      .from('users')
      .select('name, avatar_url, group_id')
      .eq('id', user.id)
      .single()

    if (profileError) {
      console.error('Error fetching profile:', profileError)
      return
    }

    // Set basic profile data
    name.value = profile.name || ''
    draftName.value = profile.name || ''

    // Handle avatar URL
    if (profile.avatar_url) {
      const signedUrl = await generateSignedUrl(profile.avatar_url)
      avatarUrl.value = signedUrl || defaultAvatar
    } else {
      avatarUrl.value = defaultAvatar
    }

    // Fetch group members separately to avoid infinite recursion
    await fetchGroupMembers(profile.group_id)
  } catch (error) {
    console.error('Error in fetchProfile:', error)
  }
}

// Only call fetchProfile once when component mounts
onMounted(() => {
  fetchProfile()
})
</script>

<style scoped>
button.change {
  all: unset;
  cursor: pointer;
  color: rgb(206, 168, 237);
  font-size: small;
  padding: 10px;
}

div.profile-picture {
  display: flex;
  flex-direction: column;
  width: 50%;
  justify-content: center;
  align-items: center;
}

div.top {
  display: flex;
  flex-direction: row;
}

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

ul {
  list-style: none;
  padding-left: 0;
}

img.profile {
  width: 8rem;
  height: 8rem;
}

img {
  width: 5rem;
  height: 5rem;
  object-fit: cover;
  border-radius: 50%;
}

li.group-member {
  display: flex;
  align-items: center;
}

li div.member-name {
  margin-left: 30px;
}
</style>
