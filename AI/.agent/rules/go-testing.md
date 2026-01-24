---
name: Go Testing
trigger: always_on
description: Golang Testing Principle
globs: **/*.go
scope: **/*.go
---

# Go Testing

function/method/struct can be categorized to aggregated one and simple one.

- Aggregated function/method/struct is like handler which combined related services logic. Don't do unit testing in this layer, but do business scenario testing/integration testing. Usually, it's handlers, controllers, etc.

- Simple function/method/struct is like service/model/config/utils. These are the unit testing focus on. Usually, it's services, models, utils, configs, etc.
