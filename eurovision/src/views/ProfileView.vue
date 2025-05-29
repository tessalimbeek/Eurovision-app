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
            <img
              :src="avatarUrl || defaultAvatar"
              alt="Profile Picture"
              class="profile"
            />
            <button @click="triggerFileSelect" class="change">
              Change
            </button>
          </div>
          
          <h1>{{ name }}</h1>
        </div>
  
        <p v-if="uploading" class="text-sm text-blue-500">Uploading...</p>
        <p v-if="uploadError" class="text-sm text-red-500">{{ uploadError }}</p>
    
        <form @submit.prevent="updateProfile" class="mb-8">
          <label for="name">Name</label>
          <input
            id="name"
            v-model="draftName"
            type="text"
            required
          />
          <button type="submit" :disabled="updating">
            {{ updating ? 'Saving...' : 'Save Changes' }}
          </button>
          <p v-if="updateError" class="text-red-500 mt-2">{{ updateError }}</p>
          <p v-if="updateSuccess" class="text-green-500 mt-2">Profile updated successfully!</p>
        </form>
    
        <h2 class="text-xl font-semibold mb-4">Group Members</h2>
        <ul v-if="groupMembers.length > 0">
          <li
            v-for="member in groupMembers"
            :key="member.id"
            class="group-member"
          >
            <img
              :src="member.avatar_url || defaultAvatar"
              alt="Member avatar"
              class="avatar"
            />
            <div class="member-name">{{ member.name }}</div>
          </li>
        </ul>
        <p v-else class="text-gray-500">You're not in any group yet.</p>
      </div>
    </main>
  </template>

<style scoped>

button.change{
    all: unset; 
    cursor: pointer;
    color: rgb(206, 168, 237);
    font-size: small;
    padding: 10px;
}

div.profile-picture{
    display: flex;
    flex-direction: column;
    width: 50%;
    justify-content: center;
    align-items: center;
}

div.top{
    display: flex;
    flex-direction: row;
}

form{
    display: flex;
    flex-direction: column;
}

input {
  font-size: 16px;
}

input[type=text], input[type=email] {
  width: 100%;
  padding: 12px 20px;
  margin: 8px 0;
  box-sizing: border-box;
}

ul {
  list-style: none;
  padding-left: 0;
}

img.profile{
    width: 8rem;
    height: 8rem;
}

img{
  width: 5rem;
  height: 5rem;
  object-fit: cover;
  border-radius: 50%;
}

li.group-member{
    display: flex;
    align-items: center;
}

li div.member-name{
    margin-left: 30px;
}
</style>

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

const uploadAvatar = async (e) => {
  const file = e.target.files[0]
  if (!file) return

  uploading.value = true
  uploadError.value = null

  const { data: authData, error: authError } = await supabase.auth.getUser()
  const user = authData?.user

  if (authError || !user) {
    uploadError.value = 'User not authenticated.'
    uploading.value = false
    return
  }

  const filePath = `${user.id}/${Date.now()}_${file.name}`

  // Upload the file to the private bucket
  const { error: uploadErr } = await supabase.storage
    .from('avatars')
    .upload(filePath, file, { upsert: true })

  if (uploadErr) {
    uploadError.value = 'Failed to upload avatar.'
    uploading.value = false
    return
  }

  // Update user record with relative path
  const { error: updateErr } = await supabase
    .from('users')
    .update({ avatar_url: filePath })
    .eq('id', user.id)

  if (updateErr) {
    uploadError.value = updateErr.message
    uploading.value = false
    return
  }

  // Generate a signed URL for displaying the image
  const { data: signedUrlData, error: signedUrlError } = await supabase
    .storage
    .from('avatars')
    .createSignedUrl(filePath, 60 * 60) // valid for 1 hour

  if (signedUrlError || !signedUrlData?.signedUrl) {
    uploadError.value = 'Could not generate image URL.'
    avatarUrl.value = defaultAvatar
  } else {
    avatarUrl.value = signedUrlData.signedUrl
  }

  uploading.value = false
}


const updateProfile = async () => {
  updating.value = true
  updateError.value = null
  updateSuccess.value = false

  const user = (await supabase.auth.getUser()).data.user

  const { error } = await supabase
    .from('users')
    .update({ name: draftName.value })
    .eq('id', user.id)

  if (error) {
    updateError.value = error.message
  } else {
    name.value = draftName.value
    updateSuccess.value = true
  }

  updating.value = false
}

const fetchProfile = async () => {
  const user = (await supabase.auth.getUser()).data.user

  const { data: profile, error } = await supabase
    .from('users')
    .select('name, avatar_url, group_id')
    .eq('id', user.id)
    .single()

  if (error) {
    console.error(error)
    return
  }

  name.value = profile.name
  draftName.value = profile.name

  console.log('avatar url:', profile.avatar_url)

  // Generate signed URL for own avatar if exists
  if (profile.avatar_url) {
    const { data: signedUrlData, error: signedUrlError } = await supabase
      .storage
      .from('avatars')
      .createSignedUrl(profile.avatar_url, 60 * 60) // 1 hour valid

    console.log('signed url:', signedUrlData)
    if (signedUrlError) {
      console.error('Failed to get signed URL for own avatar:', signedUrlError)
      avatarUrl.value = defaultAvatar
    } else {
      console.log('Else no signed url error')
      avatarUrl.value = signedUrlData.signedUrl
    }
  } else {
    console.log('Did not find user profile image')
    avatarUrl.value = defaultAvatar
  }

  console.log('User group_id:', profile.group_id)

  if (profile.group_id) {
  const { data: members, error: memberError } = await supabase
    .from('users')
    .select('id, name, avatar_url')
    .eq('group_id', profile.group_id)

  if (memberError) {
    console.error(memberError)
  } else {
    groupMembers.value = await Promise.all(
      members.map(async (member) => {
        if (member.avatar_url) {
          const { data: memberSignedUrlData, error: memberSignedUrlError } = await supabase
            .storage
            .from('avatars')
            .createSignedUrl(member.avatar_url, 60 * 60) // 1 hour valid

          if (memberSignedUrlError || !memberSignedUrlData?.signedUrl) {
            console.warn(`Failed to get signed URL for member avatar (${member.id}), using default avatar`, memberSignedUrlError)
            return { ...member, avatar_url: defaultAvatar }
          }

          return { ...member, avatar_url: memberSignedUrlData.signedUrl }
        } else {
          return { ...member, avatar_url: defaultAvatar }
        }
      })
    )
  }
}

}


onMounted(fetchProfile)
</script>

