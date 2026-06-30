# React 测试规则

## 单元测试
- 使用 Vitest 或 Jest
- 组件测试使用 React Testing Library
- 测试文件命名：*.test.tsx 或 *.spec.tsx
- 测试用户行为，而非实现细节

## 测试结构
```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { UserCard } from './UserCard'

describe('UserCard', () => {
  it('renders user name', () => {
    render(<UserCard user={{ name: 'Alice' }} onUpdate={() => {}} />)
    expect(screen.getByText('Alice')).toBeInTheDocument()
  })

  it('calls onUpdate when button clicked', () => {
    const handleUpdate = vi.fn()
    render(<UserCard user={{ name: 'Alice' }} onUpdate={handleUpdate} />)
    fireEvent.click(screen.getByRole('button'))
    expect(handleUpdate).toHaveBeenCalled()
  })
})
```

## E2E 测试
- 使用 Playwright 或 Cypress
- 覆盖关键用户流程
- 避免测试实现细节
- 使用 Page Object 模式

## Mock 和 Stub
- Mock API 调用（MSW）
- Mock Context Provider
- 避免过度 Mock

## 覆盖率
- 组件覆盖率 ≥ 70%
- 工具函数覆盖率 ≥ 90%
- 关键业务流程 100% 覆盖
