# Vue 编码模式

## 核心原则
- 使用 Composition API（setup 语法糖）
- 组件职责单一，不超过 300 行
- 状态管理使用 Pinia，避免 Vuex
- 类型安全使用 TypeScript

## 组件结构
```vue
<script setup lang="ts">
// 1. 导入
import { ref, computed } from 'vue'
import type { User } from '@/types'

// 2. Props 和 Emits
const props = defineProps<{
  user: User
}>()

const emit = defineEmits<{
  update: [user: User]
}>()

// 3. 响应式状态
const isLoading = ref(false)

// 4. 计算属性
const fullName = computed(() => `${props.user.firstName} ${props.user.lastName}`)

// 5. 方法
function handleSubmit() {
  emit('update', props.user)
}
</script>

<template>
  <!-- 模板内容 -->
</template>

<style scoped>
/* 样式 */
</style>
```

## 状态管理
- 使用 Pinia 的 setup 语法
- Store 按功能模块划分
- 避免在组件中直接修改 Store 状态
- 使用 actions 处理异步操作

## 路由
- 使用 Vue Router 4
- 路由懒加载：`() => import('./views/Home.vue')`
- 路由守卫集中管理
- 使用命名路由，避免硬编码路径

## 性能优化
- 使用 v-memo 缓存静态内容
- 列表渲染使用 v-for 时提供唯一 key
- 大列表使用虚拟滚动（vue-virtual-scroller）
- 图片懒加载（v-lazy）

## 代码组织
- 组件按功能分组：components/user/、components/common/
- 工具函数放在 utils/
- 类型定义放在 types/
- API 调用集中在 api/
