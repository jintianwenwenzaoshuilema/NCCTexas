# NCCTexas

NCCTexas 是一个使用 Godot 4 开发的德州扑克项目，包含德州扑克核心逻辑、可运行的测试牌桌界面，以及用于验证规则和界面的回归测试。

## 环境要求

- Godot 4.7 或更新的 Godot 4 版本。
- Git。
- 可选：ChatGPT、Cursor、Claude Code 等 AI 编程工具。

本项目使用 GDScript，不需要 Godot .NET/C# 版本。

## 下载 Godot

请从 Godot 官方页面下载：

- 全平台入口：https://godotengine.org/download/
- Windows：https://godotengine.org/download/windows/
- macOS：https://godotengine.org/download/macos/
- Linux：https://godotengine.org/download/linux/
- Android 编辑器：https://godotengine.org/download/android/
- Web 编辑器：https://editor.godotengine.org/

不同平台建议：

- Windows：下载标准版 Godot Engine 4.x `x86_64`，解压后运行可执行文件。
- macOS：下载适合当前 Mac 的标准版 Godot Engine 4.x，打开应用。如果首次启动被系统拦截，请在系统设置中允许打开。
- Linux：下载标准版 Godot Engine 4.x，解压后运行。如果无法启动，先给二进制文件添加可执行权限。

Godot 通常是免安装的独立程序。只有 C# 项目才需要 .NET/C# 版本，NCCTexas 不需要。

## 获取项目

克隆仓库：

```sh
git clone https://github.com/jintianwenwenzaoshuilema/NCCTexas.git
cd NCCTexas
```

如果本地已经有项目：

```sh
cd /Users/zlw/NCCTexas
git pull
```

## 打开和运行

1. 打开 Godot。
2. 点击 `Import`。
3. 选择本项目的 `project.godot` 文件。
4. 打开导入后的项目。
5. 按 `F5`，或点击右上角运行按钮。

主场景已经在 `project.godot` 中配置好，运行项目后会直接进入德州扑克测试牌桌。

也可以在命令行运行：

```sh
godot --path .
```

如果你的 Godot 命令叫 `godot4`，则使用：

```sh
godot4 --path .
```

## 运行测试

运行核心规则测试：

```sh
godot --headless --path . -s res://tests/poker_core_tests.gd
```

运行 UI 冒烟测试：

```sh
godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
```

如果你的 Godot 命令叫 `godot4`，把上面的 `godot` 替换成 `godot4`。

## 项目结构

- `project.godot`：Godot 项目配置。
- `scenes/poker_test.tscn`：主测试牌桌场景。
- `scenes/poker_test.gd`：牌桌 UI 和交互逻辑。
- `scenes/ui/card_view.tscn`：牌面视图场景。
- `scenes/ui/card_view.gd`：自绘扑克牌正面、背面和空牌位。
- `poker/`：德州扑克核心逻辑。
- `tests/`：无界面回归测试和 UI 冒烟测试。

## 开发流程

修改前：

```sh
git status
git pull
```

修改后：

```sh
godot --headless --path . -s res://tests/poker_core_tests.gd
godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
git status
git add .
git commit -m "说明本次修改"
git push
```

建议保持提交聚焦。例如，牌面视觉调整和德州扑克规则修改尽量分成不同提交。

## AI 辅助开发提示词

使用 AI 工具辅助开发时，可以直接复制下面的提示词，并把方括号里的内容替换成当前任务。

### 通用功能开发

```text
我们正在开发一个 Godot 4 德州扑克项目，项目路径是 /Users/zlw/NCCTexas。
请先阅读项目结构和相关文件，再实现这个功能：[描述要实现的功能]。
要求：
1. 遵循现有 GDScript 风格。
2. 不要覆盖无关的本地修改。
3. 如果修改扑克规则，请补充或更新测试。
4. 完成后运行：
   godot --headless --path . -s res://tests/poker_core_tests.gd
   godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
5. 最后说明改了哪些文件、测试是否通过。
```

### 修复 Bug

```text
我们正在开发 Godot 4 项目 /Users/zlw/NCCTexas。
现在有一个问题：[描述 Bug、复现步骤、期望结果和实际结果]。
请先定位原因，再做最小范围修复。
要求：
1. 不要重构无关代码。
2. 如果可以用测试覆盖，请添加回归测试。
3. 修复后运行：
   godot --headless --path . -s res://tests/poker_core_tests.gd
   godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
4. 最后说明根因、修复方式和验证结果。
```

### 调整界面

```text
我们正在开发 Godot 4 德州扑克项目 /Users/zlw/NCCTexas。
请调整牌桌界面：[描述 UI 调整目标]。
相关文件可能包括 scenes/poker_test.gd、scenes/poker_test.tscn、scenes/ui/card_view.gd、scenes/ui/card_view.tscn。
要求：
1. 保持现有视觉风格一致。
2. 不要影响德州扑克核心逻辑。
3. 注意不同窗口尺寸下的布局稳定性。
4. 修改后运行 UI 冒烟测试：
   godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
5. 最后说明界面改动和验证结果。
```

### 代码审查

```text
请审查 /Users/zlw/NCCTexas 当前工作区的修改。
重点关注：
1. 德州扑克规则是否有行为回归。
2. Godot/GDScript 写法是否可靠。
3. 是否缺少必要测试。
4. 是否有会影响运行或导入项目的问题。
请按严重程度列出问题，并给出具体文件和行号。
```

## GitHub 认证

通过 HTTPS 推送代码时，可以先配置 Git 用户信息：

```sh
git config --global user.name "你的 GitHub 用户名"
git config --global user.email "你的邮箱@example.com"
git config --global credential.helper osxkeychain
```

然后在项目目录推送：

```sh
git push
```

如果 GitHub 询问密码，请使用 GitHub personal access token，而不是 GitHub 登录密码。

SSH 认证也可以使用，但不是必须的。
