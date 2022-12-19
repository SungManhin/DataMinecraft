-- 判断视图,如果存在则删除
-- R中调用时的语句应该是
-- select cno, qno, id_num from cal_id_num
-- where cno = '课号' and qno = '作业号'
IF (EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'cal_id_num') AND OBJECTPROPERTY(id, N'IsView') = 1)) 
DROP VIEW cal_id_num;
-- 计算作业的题目数
create view cal_id_num(cno, qno, id_num)
as 
select distinct answer.cno, answer.qno,(select count(*) from question, answer where answer.cno = question.cno and question.qno=answer.qno)
from answer, question where answer.cno = question.cno and question.qno = answer.qno and question.id = answer.id

-- 实验
select cno,qno,id_num from cal_id_num

select * from answer
select * from question

-- 本次实验数据库的结构较为简单，可以使用视图功能的操作往往在R中使用dataframe实现更为直观简洁，故只展示实验操作