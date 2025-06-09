<template>
  <div
    v-if="isOpen"
    @click="closeModal"
  >
    <div
      @click.stop
    >
      <!-- Header -->
      <div class="header">
        <h2 class="title">Your Personal Top 5</h2>
        <button @click="closeModal">×</button>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
        <p class="mt-2 text-gray-600">Loading your rankings...</p>
      </div>

      <!-- No Votes State -->
      <div v-else-if="personalTop5.length === 0" class="text-center py-8">
        <p class="text-gray-500">You haven't voted for any countries yet!</p>
        <button
          @click="closeModal"
          class="mt-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          Start Voting
        </button>
      </div>

      <div v-else class="countries-list" >
        <div
          v-for="(country, index) in personalTop5"
          :key="country.country_id"
          class="country-card"
        >
          <div class="running-order">
            {{ index + 1 }}
          </div>

          <img :src="getFlagUrl(country.flag)" :alt="country.name + ' flag'" class="flag" />

          <div class="information">
            <div class="country-name">{{ country.name }}</div>
            <div class="artist">{{ country.artist_name }}</div>
            <div class="song-name">{{ country.song_name }}</div>
          </div>

          <div class="running-order score">
            {{ country.total_score }}
          </div>

        </div>
      </div>

      <!-- Footer Actions -->
      <div class="action-buttons" v-if="personalTop5.length !== 0">
          <button
            @click="shareTop5"
          >
            📤 Share Top 5
          </button>
          <button
            @click="closeModal"
          >
            ❌ Close
          </button>
        </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, nextTick  } from 'vue'
import { supabase } from '../supabase'

const props = defineProps({
  isOpen: Boolean,
  groupId: String,
  phase: String,
})

const emit = defineEmits(['close'])

const personalTop5 = ref([])
const loading = ref(false)

// Fetch user's personal top 5
const fetchPersonalTop5 = async () => {
  if (!props.groupId) return

  loading.value = true
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) return

    const isFinal = props.phase === 'final'

    const { data, error } = await supabase
      .from('votes')
      .select(
        `
          country_id,
          song,
          performance,
          vocals,
          total_score,
          countries (
            name,
            artist_name,
            song_name,
            flag,
            code
          )
        `,
      )
      .eq('user_id', user.id)
      .eq('group_id', props.groupId)
      .eq('is_final', isFinal)
      .order('total_score', { ascending: false })
      .limit(5)

    if (error) {
      console.error('Supabase error:', error)
      throw error
    }

    personalTop5.value = (data || []).map((vote) => ({
      country_id: vote.country_id,
      name: vote.countries?.name,
      artist_name: vote.countries?.artist_name,
      song_name: vote.countries?.song_name,
      code: vote.countries?.code,
      song: vote.song,
      performance: vote.performance,
      vocals: vote.vocals,
      flag: vote.countries?.flag,
      total_score: vote.total_score || vote.song + vote.performance + vote.vocals,
    }))

    personalTop5.value.sort((a, b) => b.total_score - a.total_score)
    scrollToBottom()

  } catch (error) {
    console.error('Error fetching personal top 5:', error)
    personalTop5.value = []
  } finally {
    loading.value = false
  }
}

const closeModal = () => {
  emit('close')
}

const shareTop5 = () => {
  const shareText = personalTop5.value
    .map((country, index) => `${index + 1}. ${country.name} - ${country.total_score} points`)
    .join('\n')

  if (navigator.share) {
    navigator.share({
      title: 'My Eurovision Top 5',
      text: `My Eurovision Top 5:\n\n${shareText}`,
    })
  } else {
    navigator.clipboard.writeText(`My Eurovision Top 5:\n\n${shareText}`)
    alert('Top 5 copied to clipboard!')
  }
}

watch(
  () => props.isOpen,
  (newValue) => {
    if (newValue) {
      fetchPersonalTop5()
    }
  },
)

function getFlagUrl(filename) {
  return new URL(`../assets/flags/${filename}`, import.meta.url).href
}

function scrollToBottom() {
  nextTick(() => {
    const chatBoard = document.querySelector('.main')
    if (chatBoard) {
      chatBoard.scrollTop = chatBoard.scrollHeight
    }
  })
}

</script>

<style scoped>

.header{
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
}

button{height: 40px;}


.countries-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.action-buttons{
    display: flex;
    flex-direction: row;
    justify-content: space-around;
    margin-top: 30px;
}

.country-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 1rem;
  border-radius: 10px;
  color: #fff;
  text-decoration: none;
  box-shadow: 0 0 12px 2px rgba(255, 255, 255, 0.25);
  cursor: pointer;
  user-select: none;
  position: relative;
  min-height: 50px;
}

.running-order {
  background: var(--accent-color);
  color: white;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.75rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  z-index: 1;
}

.running-order.score {
    margin-left: auto;

}

.flag {
  height: 40px;
  width: auto;
}

.information {
  line-height: 1.2;
}

.country-name {
  font-weight: 700;
  font-size: 1rem;
  text-transform: uppercase;
}

.artist,
.song-name {
  font-size: 0.85rem;
  opacity: 0.8;
}
</style>
