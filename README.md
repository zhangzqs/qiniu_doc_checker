# 介绍

本项目用于七牛文档站关于下载部分的自动化检查，主要检查以下内容：

- [x] 下载链接是否可用
- [x] url链接中的架构与文档描述架构是否匹配
- [x] 文档描述架构与实际下载文件架构是否匹配

# 编译流程

确保已经安装好dart环境，然后执行以下命令安装依赖：

```bash
dart pub get
```

执行以下命令可直接运行：

```bash
dart run bin/qiniu_doc_checker.dart config.yaml
```

执行以下命令可进行AOT编译构建出可直接运行的二进制文件：

```bash
dart compile exe bin/qiniu_doc_checker.dart -o qiniu_doc_checker
```

可直接运行二进制文件：

```bash
./qiniu_doc_checker config.yaml
```

# 注意事项

服务器端可能会返回429错误，这是因为请求过于频繁，触发了服务器端的反爬机制，等待一段时间后再次运行即可。