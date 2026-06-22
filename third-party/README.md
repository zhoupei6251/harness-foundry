# Third-Party Skill Sources（第三方 cherry-pick 存档）

> **真相源目录**。本目录保存从开源项目精选补缺的能力。
> Trae IDE 实际从 `.trae/skills/` 与 `.trae/agents/` 读取；运行时由 `scripts/sync-third-party.sh` 投影生成。

## 结构

```
third-party/
├── README.md                         # 本文件
├── superpowers/                      # 来源：obra/superpowers@v6.0.3
│   └── skills/
│       ├── subagent-driven-development/
│       ├── dispatching-parallel-agents/
│       ├── using-git-worktrees/
│       └── executing-plans/
└── ecc/                              # 来源：affaan-m/ECC@v2.0.0
    └── agents/
        ├── ecc-java-reviewer.md
        ├── ecc-java-reviewer.meta.json
        ├── ecc-security-reviewer.md
        ├── ecc-security-reviewer.meta.json
        ├── ecc-database-reviewer.md
        └── ecc-database-reviewer.meta.json
```

## 同步脚本

```bash
# 正向投影（CI / 新成员 clone 后）
bash harness-kit/scripts/sync-third-party.sh

# 反向回填（修改 .trae/ 后归档回 third-party）
bash harness-kit/scripts/sync-third-party.sh --reverse

# 干跑（仅显示计划）
bash harness-kit/scripts/sync-third-party.sh --dry-run
```

## 添加新 skill/agent

1. 在本目录对应来源下创建 `<slug>/` 或 `<name>.md`
2. 如需 meta 信息，创建 `_meta.json` 或 `.meta.json`
3. 在 `sync-third-party.sh` 中把 slug/name 加进 `SP_SKILLS` 或 `ECC_AGENTS` 数组
4. 跑 `sync-third-party.sh` 投影到 `.trae/`
5. 更新 [`harness-kit/docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md`](../docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md) 登记

## 与 sync-skills.sh 的关系

- `sync-skills.sh`：管理 harness-kit 自有 skill 投影（基于 `.agents/skills/_manifest.yaml`）
- `sync-third-party.sh`：管理第三方来源 skill/agent 投影（基于硬编码清单）

两者**正交**：前者管 harness-kit 内部，后者管外部 cherry-pick。两者均把 `SKIP_FROM_SYNC` 中的第三方 slug 排除。

## 升级流程

由于源仓库（`ECC/`、`superpowers/`）已被删除，升级时需要：

```bash
# 临时克隆上游
git clone --depth 1 https://github.com/obra/superpowers.git /tmp/sp
git clone --depth 1 https://github.com/affaan-m/ECC.git /tmp/ecc

# 对比并手工同步变更到 third-party/
diff -r /tmp/sp/skills/subagent-driven-development third-party/superpowers/skills/subagent-driven-development
cp -r /tmp/sp/skills/dispatching-parallel-agents/SKILL.md third-party/superpowers/skills/dispatching-parallel-agents/

# 更新 _meta.json 中的 source_version
# 跑 sync 投影到 .trae/
bash harness-kit/scripts/sync-third-party.sh

# 清理临时目录
rm -rf /tmp/sp /tmp/ecc
```

## 不再维护 ECC/superpowers 本地克隆的原因

- 这两个项目不是项目级别（不属于心悦 AIGC 后端代码）
- 仅在初次 cherry-pick 时使用，后续作为"参考"价值有限
- 占用项目根目录大量空间（多语言文档、rules、scripts）
- 通过 `harness-kit/third-party/` 维护自己的快照更可控
- 升级频率低（季度级），临时克隆可接受

详见 spec 文档：[`harness-kit/docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md`](../docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md)