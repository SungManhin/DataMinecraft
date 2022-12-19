# R version 4.2.2 "Innocent and Trusting"
# Platform: x86_64-w64-mingw32/x64 (64-bit)
# coding: utf-8
# author: 宋文轩
# created: 2022-11-30
# updated: 2022-12-10
# usage: building the app

library(shiny)
library(shinymanager)
library(shinyWidgets)
library(tidyverse)
library(RODBC)
library(caret)
library(cvms)
library(stringr)
source("sql&function.R")
source("read.R")


# 主 ui 
ui <- fluidPage(
  titlePanel("数据挖掘评测系统 DataMinecraft"),
  
  sidebarLayout(
    sidebarPanel(
      h4("数据挖掘课程介绍", size = 5, align = "center"),
      p(
        "数据挖掘是由中国人民大学统计学院和信息学院共同开办的数据科学系列课程，
         以介绍数据挖掘理论和实践为主要内容，本系统为课程教师和学生提供了一个可用于线上提交、批改作业的平台，
            以提高课堂教学效率，方便获取教学信息、检验教学成果。"
      ),
      
      img(
        src = "https://s1.xptou.com/2022/11/30/63864db6cfb8f.png",
        height = 105,
        width = 215
      ),
      br(),
      br(),
      ("本系统由"),
      strong("宋小轩, 姚小哲", style = "color:blue"),
      "开发",
      br(),
      br(),
      passwordInput("new_pwd", "新密码："),
      actionButton(
        inputId = "change_pwd",
        label = "确认修改",
        width = '180px',
      ),
      br(),
      textOutput("pwd_change"),
      width = 3,
      
      
    ),
    position = "right",
    mainPanel(
      conditionalPanel(condition = "output.user_info == 0",
                       h3("您是系统管理员"),
                       uiOutput("adminUI")),
      
      conditionalPanel(condition = "output.user_info == 1",
                       #h3("您登陆的是教师系统"),
                       uiOutput("teacherUI")),
      
      conditionalPanel(condition = "output.user_info == 2",
                       h3("您登陆的是学生系统"),
                       uiOutput("studentUI")),
      
      
      
    )
  ),
  
  
)

# 将 app 页面通过登录页包装
ui <- secure_app(ui, background = "linear-gradient(rgba(172,203,238,1.0),
                       rgba(231,240,253,1.0));")



# 主 server
server <- function(input, output, session) {
  
  # 登录环节
  res_auth <- secure_server(check_credentials = check_credentials(credentials))
  
  
  output$user_info <- reactive({
    if (reactiveValuesToList(res_auth)$user == "1") {
      return(0)
    } else if (reactiveValuesToList(res_auth)$user %in% teacher_inf$tno) {
      return(1)
    } else if (reactiveValuesToList(res_auth)$user %in% student_inf$sno) {
      return(2)
    }
  })
  

  
  outputOptions(output, "user_info", suspendWhenHidden = F)
  
  # 管理员 ui
  output$adminUI = renderUI({
    h3("您是超级管理员")
    sidebarLayout(
      sidebarPanel(
        verticalLayout(
          fileInput(
            "sinf",
            '学生信息上传',
            accept = c('csv', 'comma-separated-values', '.csv'),
            buttonLabel = "浏览...",
            placeholder = "未选择文件",
          ),
          fileInput(
            "tinf",
            '教师信息上传',
            accept = c('csv', 'comma-separated-values', '.csv'),
            buttonLabel = "浏览...",
            placeholder = "未选择文件",
          ),
          fileInput(
            "cinf",
            '课程信息上传',
            accept = c('csv', 'comma-separated-values', '.csv'),
            buttonLabel = "浏览...",
            placeholder = "未选择文件",
          ),
          fileInput(
            "scinf",
            '选课信息上传',
            accept = c('csv', 'comma-separated-values', '.csv'),
            buttonLabel = "浏览...",
            placeholder = "未选择文件",
          ),
          actionButton("admin_upload_tag", "上传信息", width = "140px"),
          textOutput("admin_upload_success")
        )
      ),
      
      mainPanel(
        splitLayout(
          actionButton("show_total_teacher_trig", "刷新教师人数", width = "155px"),
          actionButton("show_total_student_trig", "刷新学生人数", width = "155px"),
          actionButton("show_total_course_trig", "刷新课程总数", width = "155px")
          
          
        ),
        splitLayout(
          cellWidtgs = c("80px", "80px"),
          statiCard(
            0,
            "教师人数",
            icon("chalkboard-user"),
            background = "dodgerblue",
            color = "white",
            animate = TRUE,
            id = "card1",
            
          ),
          statiCard(
            0,
            "学生人数",
            icon("user"),
            background = "tomato",
            color = "white",
            animate = TRUE,
            id = "card2"
          ),
          
          
          
          
        ),
        br(),
        splitLayout(
          cellWidtgs = c("80px", "80px"),
          statiCard(
            time.welcome(),
            paste0("管理员，", sample(
              c("今天运动了吗？", "记得检查系统哦", "保持好心情哦", "记得戴口罩哦"), 1
            )),
            icon("lock-open"),
            background = "orange",
            color = "white",
            animate = TRUE,
            id = "card3"
          ),
          statiCard(
            0,
            "当前课程总数",
            icon("book-open"),
            background = "mediumseagreen",
            color = "white",
            animate = TRUE,
            id = "card4"
          ),
          
          
        )
        
      )
      
      
      
      
      
    )
    
  })
  # 教师 ui
  output$teacherUI = renderUI({
    t_class_choices = cno2cname(t_class.query(reactiveValuesToList(res_auth)$user))
    
    sidebarLayout(
      sidebarPanel(
        verticalLayout(
          h4(paste0(
            time.welcome(), "，", teacher_inf$tname[which(teacher_inf$tno == reactiveValuesToList(res_auth)$user)], "老师"
          )),
          selectInput("t_class_choice",
                      "选择课程",
                      choices = t_class_choices),
          selectInput("t_hw_choice",
                      "选择作业次数",
                      choices = hw_choices),
          fileInput(
            "std_ans",
            '上传标准答案',
            accept = c('csv', 'comma-separated-values', '.csv'),
            buttonLabel = "浏览...",
            placeholder = "未选择文件",
            width = "185px"
          ),
          actionButton("upload_std_ans_trig", "提交答案", width = "140px"),
          textOutput("uploadtag_std_ans"),
          br(),
          fileInput(
            "grade",
            '上传学生成绩',
            accept = c('csv', 'comma-separated-values', '.csv'),
            buttonLabel = "浏览...",
            placeholder = "未选择文件",
          ),
          actionButton("upload_grade_trig", "提交成绩", width = "140px"),
          textOutput("uploadtag_grade")
        )
      ),
      
      mainPanel(
        actionButton("show_sinf_trig", "查看学生课程信息", width = "200px"),
        br(),
        h5("当前课程名单："),
        tableOutput("sinf_table")
      )
    )
    
  })
  # 学生 ui
  output$studentUI = renderUI({
    s_class_choices = cno2cname(s_class.query(reactiveValuesToList(res_auth)$user))
    
    sidebarLayout(
      sidebarPanel(
        verticalLayout(
          h4(paste0(
            time.welcome(), "，", student_inf$sname[which(student_inf$sno == reactiveValuesToList(res_auth)$user)], "同学"
          )),
          selectInput("s_class_choice",
                      "选择课程",
                      choices = s_class_choices),
          selectInput("s_hw_choice",
                      "选择作业次数",
                      choices = hw_choices),
          selectInput("upload_choice",
                      "选择提交次数",
                      choices = upload_choices),
          fileInput(
            "ans",
            '上传作业',
            accept = c('csv', 'comma-separated-values', '.csv'),
            buttonLabel = "浏览...",
            placeholder = "未选择文件",
            width = "185px"
          ),
          actionButton("upload_ans_trig", "提交作业", width = "140px"),
          textOutput("uploadtag_ans"),
          
          
        )
      ),
      
      mainPanel(
        splitLayout(
          cellWidths = c("40%", "47%", "40%"),
          actionButton("result_trig", "查看作业预测结果", width = "140px"),
          actionButton("accuracy_trig", "生成正确率曲线", width = "140px"),
          actionButton("sgrade_trig", "查询成绩", width = "135px"),
        ),
        verticalLayout(
          br(),
          strong("你的课程成绩"),
          tableOutput("sgrade_table"),
          
          strong("你的作业结果分析"),
          tableOutput("overall"),
          tableOutput("byclass"),
          plotOutput("cm_plot"),
          br(),
          strong("你的正确率曲线"),
          plotOutput("accuracy_plot")
        ),
        width = 6
        
        
      )
    )
  })
  
  observeEvent(input$show_total_teacher_trig, {
    updateStatiCard(id = "card1",
                    value = dim(teacher_inf)[1])
  })
  
  observeEvent(input$show_total_student_trig, {
    updateStatiCard(id = "card2",
                    value = dim(student_inf)[1])
  })
  
  observeEvent(input$show_total_course_trig, {
    updateStatiCard(id = "card4",
                    value = dim(course_inf)[1])
  })
  
  # 修改密码
  output$pwd_change = eventReactive(input$change_pwd, {
    pwd_change(reactiveValuesToList(res_auth)$user, input$new_pwd)
  })
  
  # 上传教师、学生和课程信息
  output$admin_upload_success = eventReactive(input$admin_upload_tag, {
    upload_information(
      req(input$sinf)$datapath,
      req(input$tinf)$datapath,
      req(input$cinf)$datapath,
      req(input$scinf)$datapath
    )
    
  })

  # 上传学生答案和标准答案
  output$uploadtag_ans = eventReactive(input$upload_ans_trig, {
    ans.upload(
      req(input$ans)$datapath,
      reactiveValuesToList(res_auth)$user,
      req(cname2cno(input$s_class_choice)),
      req(input$s_hw_choice),
      req(input$upload_choice)
    )
    
  })
  
  output$uploadtag_std_ans = eventReactive(input$upload_std_ans_trig, {
    std_ans.upload(req(input$std_ans)$datapath,
                   req(cname2cno(input$t_class_choice)),
                   req(input$t_hw_choice))
    
  })
  
  # 上传学生成绩
  output$uploadtag_grade = eventReactive(input$upload_grade_trig, {
    grade.upload(req(input$grade)$datapath, req(cname2cno(input$t_class_choice)))
  })
  
  # 展示选课学生信息
  show_sinf = eventReactive(input$show_sinf_trig, {
    sinf.show(req(cname2cno(input$t_class_choice)))
  })
  
  # 学生自查成绩
  sgrade_query = eventReactive(input$sgrade_trig, {
    sgrade.show(reactiveValuesToList(res_auth)$user, req(cname2cno(input$s_class_choice)))
  })
  
  # 查询分类结果
  result_byclass = eventReactive(input$result_trig, {
    answer.query(
      reactiveValuesToList(res_auth)$user,
      req(cname2cno(input$s_class_choice)),
      req(input$t_hw_choice),
      req(input$upload_choice)
    )$df1
  })
  
  result_overall = eventReactive(input$result_trig, {
    answer.query(
      reactiveValuesToList(res_auth)$user,
      req(cname2cno(input$s_class_choice)),
      req(input$t_hw_choice),
      req(input$upload_choice)
    )$df2
  })
  
  plot_tibble = eventReactive(input$result_trig, {
    answer.query(
      reactiveValuesToList(res_auth)$user,
      req(cname2cno(input$s_class_choice)),
      req(input$t_hw_choice),
      req(input$upload_choice)
    )$cm
  })
  
  # 生成每次提交准确率的列表
  accuracy_history = eventReactive(input$accuracy_trig, {
    accuracy_list <<-
      c(
        accuracy_list,
        answer.query(
          reactiveValuesToList(res_auth)$user,
          req(cname2cno(input$s_class_choice)),
          req(input$t_hw_choice),
          req(input$upload_choice)
        )$df2$准确率
      )
    accuracy_list
  })
  
  output$sinf_table = renderTable({
    show_sinf()
  }, rownames = TRUE, align = "c", width = "450px")
  
  output$sgrade_table = renderTable({
    sgrade_query()
  }, rownames = FALSE, align = "c", width = "450px")
  
  # 生成图表并传到 ui
  output$byclass = renderTable({
    result_byclass()
  }, rownames = TRUE, align = "c", width = "440px")
  
  output$overall = renderTable({
    result_overall()
  }, align = "c", width = "440px")
  
  output$cm_plot = renderPlot({
    plot_confusion_matrix(
      plot_tibble(),
      target_col = "target",
      prediction_col = "prediction",
      counts_col = "n",
      palette = sample(palette.bar, 1),
      darkness = 0.6
    )
    
  }, width = 490)
  
  output$accuracy_plot = renderPlot({
    accuracy_plot(accuracy_history())
    
  }, width = 490)
  
  
  
  
}
accuracy_list = c()
shinyApp(ui, server)
