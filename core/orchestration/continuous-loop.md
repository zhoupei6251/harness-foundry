# Continuous Loop（连续循环模式）

> opt-in 功能。代码域专用，需用户明确启用。

## 触发

用户说"连续循环" / "进入维护模式" / "持续优化" 且明确 opt-in。

默认模式为 `single-pass`（单次完成即停止）。

## 机制

1. Leader 完成一个 GROUP 的 WU
2. 尾盘 collective-test + code-review 通过
3. Leader 检查 HANDOFF.md 中是否有下一批 WU
4. 有 → 自动进入下一 GROUP；无 → 停止
5. 每轮暂停等用户确认

## 配置

见 `core/orchestration/config.defaults.yaml`：
```yaml
code:
  runtime:
    loop_mode: single-pass   # 改为 continuous 启用
```

## 禁止

- 默认启用（必须 opt-in）
- 无人值守的自动 commit/push
- 跳过阶段门禁
