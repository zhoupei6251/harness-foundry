# Vue 测试规则

## 单元测试
- 使用 Vitest 作为测试框架
- 组件测试使用 @vue/test-utils
- 测试文件命名：*.spec.ts 或 *.test.ts
- 测试覆盖：组件渲染、用户交互、状态变化

## 测试结构
```typescript
import { mount } from '@vue/test-utils'
import UserCard from './UserCard.vue'

describe('UserCard', () => {
  it('renders user name', () => {
    const wrapper = mount(UserCard, {
      props: { user: { name: 'Alice' } }
    })
    expect(wrapper.text()).toContain('Alice')
  })

  it('emits update event on click', async () => {
    const wrapper = mount(UserCard, {
      props: { user: { name: 'Alice' } }
    })
    await wrapper.find('button').trigger('click')
    expect(wrapper.emitted('update')).toBeTruthy()
  })
})
```

## E2E 测试
- 使用 Playwright 或 Cypress
- 覆盖关键用户流程
- 避免测试实现细节，测试用户行为
- 使用 Page Object 模式组织代码

## Mock 和 Stub
- Mock API 调用（MSW 或 vitest mock）
- Mock Pinia Store
- 避免过度 Mock

## 覆盖率
- 组件覆盖率 ≥ 70%
- 工具函数覆盖率 ≥ 90%
- 关键业务流程 100% 覆盖
