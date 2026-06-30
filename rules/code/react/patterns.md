# React 编码模式

## 核心原则
- 使用函数组件 + Hooks
- 组件职责单一，不超过 200 行
- 状态管理优先使用 Context，复杂场景用 Redux/Zustand
- 类型安全使用 TypeScript

## 组件结构
```typescript
import { useState, useEffect } from 'react'
import type { User } from '@/types'

interface UserCardProps {
  user: User
  onUpdate: (user: User) => void
}

export function UserCard({ user, onUpdate }: UserCardProps) {
  const [isLoading, setIsLoading] = useState(false)
  
  useEffect(() => {
    // 副作用
  }, [user.id])
  
  const handleSubmit = () => {
    onUpdate(user)
  }
  
  return (
    <div>
      {/* JSX */}
    </div>
  )
}
```

## Hooks 使用
- 自定义 Hook 以 use 开头
- useEffect 必须声明依赖数组
- 避免在循环/条件中使用 Hooks
- 复杂状态使用 useReducer

## 性能优化
- 使用 React.memo 缓存组件
- 使用 useMemo 缓存计算结果
- 使用 useCallback 缓存函数
- 列表渲染提供唯一 key

## 状态管理
- 局部状态用 useState
- 跨组件状态用 Context
- 全局状态用 Redux Toolkit 或 Zustand
- 服务端状态用 React Query

## 代码组织
- 组件按功能分组：components/user/、components/common/
- Hooks 放在 hooks/ 目录
- 工具函数放在 utils/
- 类型定义放在 types/
- API 调用集中在 api/
