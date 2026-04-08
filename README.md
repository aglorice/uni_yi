# Uni Yi

五邑大学一站式校园助手 App，基于 Flutter 构建，支持 Android、iOS、Web、macOS、Windows、Linux 多平台。

## 功能

- **统一身份认证** — 通过学校 SSO 统一登录，安全存储凭证
- **课程表** — 按周/今日查看课程安排，支持多学期切换
- **成绩查询** — 查看各学期成绩信息
- **考试安排** — 查看考试时间、地点等信息
- **体育馆预约** — 查看场地并在线预约
- **电费查询** — 监控宿舍用电情况
- **个人主页** — 主题切换、字体调节、深色模式等个性化设置

## 技术栈

| 类别 | 技术 |
| --- | --- |
| 框架 | Flutter 3.29+ (Dart 3.9+) |
| 状态管理 | Riverpod |
| 路由 | GoRouter |
| 网络请求 | Dio |
| 本地存储 | SharedPreferences + FlutterSecureStorage |
| 加密 | encrypt (AES) |
| 架构 | Clean Architecture + 领域驱动设计 |

## 项目结构

```
lib/
├── main.dart                  # 应用入口
├── app/                       # 应用配置
│   ├── bootstrap/             # 初始化
│   ├── di/                    # 依赖注入
│   ├── router/                # 路由
│   ├── settings/              # 偏好设置
│   ├── shell/                 # 导航外壳
│   └── theme/                 # 主题
├── core/                      # 核心工具
│   ├── error/                 # 错误处理
│   ├── logging/               # 日志
│   ├── models/                # 基础模型
│   ├── network/               # 网络层
│   ├── result/                # Result 模式
│   └── storage/               # 存储工具
├── integrations/              # 外部集成
│   └── school_portal/         # 学校教务系统集成
│       ├── clients/           # API 客户端
│       ├── dto/               # 数据传输对象
│       ├── mappers/           # 数据映射
│       ├── parsers/           # 响应解析
│       └── sso/               # SSO 认证
├── modules/                   # 功能模块
│   ├── auth/                  # 认证
│   ├── electricity/           # 电费
│   ├── exams/                 # 考试
│   ├── grades/                # 成绩
│   ├── gym_booking/           # 体育馆预约
│   ├── home/                  # 首页
│   ├── profile/               # 个人中心
│   └── schedule/              # 课程表
└── shared/                    # 共享组件
```

## 开发

### 环境要求

- Flutter SDK >= 3.29.0
- Dart SDK >= 3.9.2
- Android Studio / VS Code
- Android SDK (Android 开发)
- Xcode 15+ (iOS/macOS 开发，仅 macOS)

### 快速开始

```bash
# 克隆项目
git clone https://github.com/<your-username>/uni_yi.git
cd uni_yi

# 安装依赖
flutter pub get

# 运行
flutter run

# 运行测试
flutter test

# 代码分析
flutter analyze
```

### 构建

```bash
# Android APK
flutter build apk

# Android App Bundle (上架 Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web

# macOS / Windows / Linux
flutter build macos
flutter build windows
flutter build linux
```

## 发布

项目使用 GitHub Actions 自动构建和发布。推送 tag 即可触发：

```bash
# 创建并推送版本标签
git tag v1.0.0
git push origin v1.0.0
```

Workflow 会自动构建 Android APK 并创建 GitHub Release。

## License

本项目仅供学习和研究使用。