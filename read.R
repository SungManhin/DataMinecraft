# R version 4.2.2 "Innocent and Trusting"
# Platform: x86_64-w64-mingw32/x64 (64-bit)
# coding: utf-8
# author: 宋文轩
# created: 2022-11-30
# updated: 2022-12-10
# usage: read information needed for the app

channel = odbcConnect('RSCT', uid = 'SungManhin')

# 读取信息
teacher_inf = sqlQuery(channel, "select tname, tno, tpwd from teacher")
student_inf = sqlQuery(channel, "select sname, sno, spwd from student")
course_inf = sqlQuery(channel, "select cno, cname, ccredit from course")

odbcClose(channel)

# 为每个老师的每门课程提供 20 次作业数量
# 每位同学针对一次作业最多提交 20 次
hw_choices = as.character(1:20)
upload_choices = as.character(1:20)
accuracy_list = c()


# 定义权限
credentials <- data.frame(
  user = c("1", teacher_inf$tno, student_inf$sno),
  # mandatory
  password = c("1", teacher_inf$tpwd, student_inf$spwd),
  # mandatory
  admin = c(TRUE, rep(
    FALSE, dim(teacher_inf)[1] + dim(student_inf)[1]
  )),
  stringsAsFactors = FALSE
)

# 汉化标签
set_labels(
  language = "en",
  "Please authenticate" = "数据挖掘评测系统 DataMinecraft",
  "Username:" = "学工号/职工号",
  "Password:" = "密码",
  "Login" = "登录",
  "Please change your password" = strong("密码修改"),
  "New password:" = "新密码",
  "Confirm password:" = "确认密码",
  "Password must contain at least one number, one lowercase, one uppercase and must be at least length 6." =
    "新密码必须包含大写字母，小写字母和数字，密码长度不能小于6",
  "Update new password" = "更新密码"
  
)

# 调色板预读取
palette.bar = c(
  "Blues",
  "BuGn",
  "BuPu",
  "GnBu",
  "Greens",
  "Oranges",
  "OrRd",
  "PuBu",
  "PuBuGn",
  "PuRd",
  "Purples",
  "RdPu",
  "Reds",
  "YlGn",
  "YlGnBu",
  "YlOrBr",
  "YlOrRd",
  "Set1",
  "Set2",
  "Set3",
  "Paired",
  "Pastel1",
  "Pastel2"
)