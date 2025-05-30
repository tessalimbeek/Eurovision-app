<script setup>
import { defineProps } from 'vue'

const props = defineProps({
  country: {
    type: Object,
    required: true,
  },
  phase: {
    type: String,
    default: 'semi1', // semi1, semi2, or final
  },
})

function getFlagUrl(filename) {
  return new URL(`../assets/flags/${filename}`, import.meta.url).href
}

// Get the appropriate running order based on phase
function getRunningOrder() {
  if (props.phase === 'final') {
    return props.country.final_running_order
  } else {
    return props.country.semi_running_order
  }
}
</script>

<template>
  <RouterLink :to="{ name: 'VotingPage', params: { countryId: country.id } }" class="country-card">
    <div class="running-order" v-if="getRunningOrder()">
      {{ getRunningOrder() }}
    </div>

    <img :src="getFlagUrl(country.flag)" :alt="country.name + ' flag'" class="flag" />

    <div class="information">
      <div class="country-name">{{ country.name }}</div>
      <div class="artist">{{ country.artist_name }}</div>
      <div class="song-name">{{ country.song_name }}</div>
    </div>
  </RouterLink>
</template>

<style scoped>
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
}

.running-order {
  position: absolute;
  top: -8px;
  right: -8px;
  background: var(--accent-color);
  color: white;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.75rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  z-index: 1;
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
