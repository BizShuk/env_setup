---
trigger: always_on
description: Golang SDK to use by default
globs: **/*.go
scope: **/*.go
---

This is languange I prefer by default if project level GEMINI.md is not explicitly mentioning the programming language to use. 

There are few SDKs to use by default.

- github.com/bizshuk/gosdk
- github.com/go-gorm/gorm
- github.com/spf13/viper
- github.com/spf13/cobra
- go.uber.org/zap, every error handling need to have a log to print out error.
  