# R version 4.2.2 "Innocent and Trusting"
# Platform: x86_64-w64-mingw32/x64 (64-bit)
# coding: utf-8
# author: 宋文轩
# created: 2022-11-30
# updated: 2022-12-10
# usage: functions used to build the app


# 密码修改
pwd_change = function(user, pwd) {
  query1 = paste0("update student set spwd=", pwd, " where sno=", user)
  query2 = paste0("update teacher set tpwd=", pwd, " where tno=", user)
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  if (str_length(user) < 10) {
    sqlQuery(myConn, query2)
  }
  else{
    sqlQuery(myConn, query1)
  }
  odbcClose(myConn)
  return("修改成功！")
}



# 系统管理员信息上传
upload_information = function(path1, path2, path3, path4) {
  student = read.csv(path1)
  teacher = read.csv(path2)
  course = read.csv(path3)
  sc = read.csv(path4)
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  sqlSave(
    myConn,
    student,
    tablename = "student",
    append = T,
    rownames = F,
    verbose = T
  )
  sqlSave(
    myConn,
    teacher,
    tablename = "teacher",
    append = T,
    rownames = F,
    verbose = T
  )
  sqlSave(
    myConn,
    course,
    tablename = "course",
    append = T,
    rownames = F,
    verbose = T
  )
  sqlSave(
    myConn,
    sc,
    tablename = "sc",
    append = T,
    rownames = F,
    verbose = T
  )
  odbcClose(myConn)
  return("信息上传成功！")
}


# 学生上传答案
ans.upload = function(path, sno, cno, qno, aid) {
  data = read.csv(path)
  n = dim(data)[1]
  data$sno = rep(sno, n)
  data$cno = rep(cno, n)
  data$qno = rep(qno, n)
  data$aid = rep(aid, n)
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  sqlSave(
    myConn,
    data,
    tablename = "answer",
    append = T,
    rownames = F,
    verbose = T
  )
  odbcClose(myConn)
  return("上传成功！")
}

# 教师上传标准答案
std_ans.upload = function(path, cno, qno) {
  data = read.csv(path)
  n = dim(data)[1]
  data$cno = rep(cno, n)
  data$qno = rep(qno, n)
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  sqlSave(
    myConn,
    data,
    tablename = "question",
    append = T,
    rownames = F
  )
  odbcClose(myConn)
  return("上传成功！")
}

# 教师上传成绩
grade.upload = function(path, cno) {
  data = read.csv(path)
  n = dim(data)[1]
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  for (i in 1:n) {
    query = paste0("update sc set grade=",
                   data$grade[i],
                   " where sno=",
                   data$sno[i],
                   " and cno=",
                   cno)
    sqlQuery(myConn, query)
  }
  odbcClose(myConn)
  return("上传成功！")
}

# 教师查询所教课程的学生信息
sinf.show = function(cno) {
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  query = paste0("select * from sc where cno=", cno)
  data_raw = sqlQuery(myConn, query)
  odbcClose(myConn)
  n = dim(data_raw)[1]
  grade = c()
  gpa = c()
  for (i in 1:n) {
    grade[i] = ifelse(is.na(data_raw$grade[i]), "暂无成绩", data_raw$grade[i])
    gpa[i] = ifelse(is.na(data_raw$grade[i]),
                    "暂无绩点",
                    grade2GPA(data_raw$grade[i]))
  }
  data = data.frame(学号 = data_raw$sno, 成绩 = grade, 绩点 = gpa)
  return(data)
}

# 学生查询所选课程成绩
sgrade.show = function(sno, cno) {
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  query1 = paste0("select cno from sc where cno=", cno, " and sno=", sno)
  if (is_empty(sqlQuery(myConn, query1)$cno)) {
    return(data.frame(课程名 = cno2cname(cno), 错误信息 = "未选此课！"))
  }
  query2 = paste0("select cno, grade from sc where cno=", cno, " and sno=", sno)
  data_raw = sqlQuery(myConn, query2)
  odbcClose(myConn)
  data = data.frame(
    课程名 = cno2cname(cno),
    分数 = ifelse(is.na(data_raw$grade), "暂无成绩", data_raw$grade),
    绩点 = ifelse(is.na(data_raw$grade), "暂无成绩", grade2GPA(data_raw$grade))
  )
  return(data)
  
}

# 学生上传答案查询和分析一体化
answer.query = function(sno, cno, qno, aid)
{
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  
  query1 = paste0(
    "select id, ans from SCT.dbo.answer where sno=",
    sno,
    " and cno=",
    cno,
    " and qno=",
    qno,
    " and aid=",
    aid,
    " order by id"
  )
  ans = sqlQuery(myConn, query1)
  
  query2 = paste0(
    "select id, std_ans from SCT.dbo.question where cno=",
    cno,
    " and qno=",
    qno,
    " order by id"
  )
  std_ans = sqlQuery(myConn, query2)
  
  odbcClose(myConn)
  
  
  cm = as.matrix(table(target = std_ans$std_ans, prediction = ans$ans))
  n = nrow(cm)
  
  if (n == 2) {
    accuracy = sum(diag(cm)) / sum(cm)
    
    precision = diag(cm) / apply(cm, 2, sum)
    recall = diag(cm) / apply(cm, 1, sum)
    f1 = 2 * precision * recall / (precision + recall)
    kappa = confusionMatrix(cm)$overall[2]
    accuracypvalue = confusionMatrix(cm)$overall[6]
    Mcnemarpvalue = confusionMatrix(cm)$overall[7]
    
    cm.tibble = as_tibble(cm)
    
    df1 = data.frame("查全率" = recall,
                     "查准率" = precision,
                     "f1" = f1)
    rownames(df1) = 1:n
    
    df2 = data.frame(
      "准确率" = accuracy,
      "Kappa 统计量" = kappa,
      "准确率检验p值" = accuracypvalue,
      "McNemar检验p值" = Mcnemarpvalue
    )
    return(list(cm = cm.tibble, df1 = df1, df2 = df2))
  }
  
  cm = as.matrix(table(prediction = ans$ans, target = std_ans$std_ans))
  accuracy = sum(diag(cm)) / sum(cm)
  
  cm.tibble = as_tibble(cm)
  
  cm = confusionMatrix(cm)
  
  
  precision = cm$byClass[, 5]
  recall = cm$byClass[, 6]
  sensitivity = cm$byClass[, 1]
  specificity = cm$byClass[, 2]
  f1 = cm$byClass[, 7]
  
  kappa = cm$overall[2]
  accuracypvalue = cm$overall[6]
  Mcnemarpvalue = cm$overall[7]
  
  
  df1 = data.frame(
    "查全率" = recall,
    "查准率" = precision,
    "灵敏性" = sensitivity,
    "特异性" = specificity,
    "f1" = f1
  )
  rownames(df1) = 1:n
  
  df2 = data.frame(
    "准确率" = accuracy,
    "Kappa统计量" = kappa,
    "准确率检验p值" = accuracypvalue,
    "McNemar检验p值" = Mcnemarpvalue
  )
  
  return(list(cm = cm.tibble, df1 = df1, df2 = df2))
}

# 教师所教课程查询
t_class.query = function(tno) {
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  query = paste0(
    "select cno from SCT.dbo.course, SCT.dbo.teacher where SCT.dbo.teacher.tno=SCT.dbo.course.tno and SCT.dbo.teacher.tno=",
    tno
  )
  cno = sqlQuery(myConn, query)$cno
  odbcClose(myConn)
  return(cno)
}

# 学生所选课程查询
s_class.query = function(sno) {
  myConn = odbcConnect('RSCT', uid = 'SungManhin')
  query = paste0("select cno from SCT.dbo.sc where sno=", sno)
  cno = sqlQuery(myConn, query)$cno
  odbcClose(myConn)
  return(cno)
}

# 时间问候语
time.welcome = function() {
  hour = format(lubridate::now(), "%H")
  mnight = c("00", "01", "02", "03", "04")
  morning = c("05", "06", "07", "08", "09", "10", "11")
  noon = c("12")
  afternoon = c("13", "14", "15", "16", "17")
  night = c("18", "19", "20", "21", "22", "23")
  if (hour %in% mnight) {
    return ("晚安")
  }
  if (hour %in% morning) {
    return ("早上好")
  }
  if (hour %in% noon) {
    return ("中午好")
  }
  if (hour %in% afternoon) {
    return ("下午好")
  }
  if (hour %in% night) {
    return ("晚上好")
  }
}

# 准确率可视化
accuracy_plot = function(data, aid) {
  df = data.frame(x = as.factor(c(0, 1:length(data))), y = c(0, data))
  return(
    ggplot(df, aes(
      x = x,
      y = y,
      group = 1,
      color = 1
    )) + geom_line(size = .9) +
      geom_point(size = 1.6) + xlab("点击次数") + ylab("正确率") +
      ylim(0, 1) + theme(legend.position = "none")
  )
}

# 课程号转换为课程名
cno2cname = function(cno) {
  if (is_empty(cno)) {
    return("暂无课程")
  }
  cname = course_inf$cname[which(course_inf$cno %in% cno)]
  if (is_empty(cname)) {
    return("暂无课程")
  }
  return(cname)
}

# 课程名转换为课程号
cname2cno = function(cname) {
  if (is_empty(cname)) {
    return("000")
  }
  cno = course_inf$cno[which(course_inf$cname %in% cname)]
  if (is_empty(cno)) {
    return("000")
  }
  return(cno)
}

# 成绩与 GPA 转换
grade2GPA = function(grade) {
  if (grade <= 100 & grade >= 90) {
    return("4.0")
  } else if (grade < 90 & grade >= 86) {
    return("3.7")
  } else if (grade < 86 & grade >= 83) {
    return("3.3")
  } else if (grade < 83 & grade >= 80) {
    return("3.0")
  } else if (grade < 80 & grade >= 76) {
    return("2.7")
  } else if (grade < 76 & grade >= 73) {
    return("2.3")
  } else if (grade < 73 & grade >= 70) {
    return("2.0")
  } else if (grade < 70 & grade >= 66) {
    return("1.7")
  } else if (grade < 66 & grade >= 63) {
    return("1.3")
  } else if (grade < 63 & grade >= 60) {
    return("1.0")
  } else if (grade < 60) {
    return("未合格")
  }
}
