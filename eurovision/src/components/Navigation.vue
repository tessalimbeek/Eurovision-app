<script setup>
import { useRoute } from 'vue-router'

const route = useRoute()
import { unreadCount } from '../composables/chatState'

const items = [
  { to: '/home',        label: 'Home',   icon: 'home'   },
  { to: '/scores',  label: 'Scores', icon: 'star'   },
  { to: '/chat',    label: 'chat',   icon: 'chat'   },
  { to: '/profile', label: 'profile', icon: 'profile'  },
]
</script>

<template>
    <nav class="mobile-nav bottom-nav">
      <RouterLink
        v-for="item in items"
        :key="item.to"
        :to="item.to"
        class="nav-item"
        :class="{ active: route.path === item.to }"
      >
        <div class="icon-wrapper">
          <!-- SVG icons -->
          <svg v-if="item.icon === 'home'"      xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path stroke="currentColor" stroke-width="1.5" d="M3 9.5 12 3l9 6.5V21a.5.5 0 0 1-.5.5H3.5a.5.5 0 0 1-.5-.5V9.5Z"/><path stroke="currentColor" stroke-width="1.5" d="M9 21V12h6v9"/></svg>
          <svg v-else-if="item.icon === 'star'" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path stroke="currentColor" stroke-width="1.5" d="m12 3 2.7 6.9 7.3.6-5.5 4.9 1.7 7.1L12 17.8 5.8 22.5l1.7-7.1L2 10.5l7.3-.6L12 3Z"/></svg>
          <svg v-else-if="item.icon === 'chat'" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path stroke="currentColor" stroke-width="1.5" d="M2.5 7.5h19M5 12.5h14m-8 5h8"/></svg>
          <svg v-else                           xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path stroke="currentColor" stroke-width="1.5" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"/></svg>
  
          <!-- Unread message badge -->
          <sup
            v-if="item.to === '/chat' && unreadCount > 0"
            class="badge"
          >
            {{ unreadCount }}
          </sup>
        </div>
  
        <span>{{ item.label }}</span>
      </RouterLink>
    </nav>
  </template>
  

<style scoped>

.icon-wrapper {
  position: relative;
  display: inline-block;
}

.badge {
  position: absolute;
  top: -4px;
  right: -8px;
  background: red;
  color: white;
  font-size: 10px;
  padding: 2px 5px;
  border-radius: 12px;
  font-weight: bold;
  line-height: 1;
}


.mobile-nav{
  position: fixed;
  bottom: 0;
  width: 100%;
  display:flex;
  justify-content:space-around;
  background:#fff;
  padding:10px 0 20px;
  border-top:1px solid #e5e7eb; /* light gray */
}

.nav-item{
  display:flex;
  flex-direction:column;
  align-items:center;
  font-size:12px;
  color:#6b7280;             
  text-decoration:none;
}

.nav-item svg{
  width:24px;
  height:24px;
  margin-bottom:2px;
}

.nav-item.active{
  color: var(--background-color);             
}

.nav-item.active svg{
  stroke: var(--background-color);
}
</style>
