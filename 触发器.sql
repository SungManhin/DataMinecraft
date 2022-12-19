-- use SCT;

-- trigger1
-- 判断触发器,如果存在则删除
IF (EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'Std_ans_update_trig') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)) 
DROP TRIGGER Std_ans_update_trig;

-- 上传标准答案的触发器（如果重复上传则更新）
create trigger Std_ans_update_trig on question
	instead of insert
as
	declare @cno char(10)
	declare @cname char(20)
	declare @qno char(10)
	declare @id char(10)
	declare @std_ans char(10)
	-- 插入的课程号，作业号，题号，标准答案
	select @std_ans = std_ans from inserted
	select @cno = cno from inserted
	select @id = id from inserted
	select @qno = qno from inserted
	-- 对应的课程名
	select @cname = (select cname from course where cno = @cno);
	-- 如果标准答案不为空，即已有标准答案
	if (exists(select std_ans from question where @cno = cno and @qno = qno))
	begin
		-- 打印提示指令
		print '您将要更新'+convert(char,@cname)+'的第'+convert(char,@qno)+'次作业的标准答案' 
		-- 修改标准答案
		update question
		set std_ans = @std_ans
		where @cno = cno and @id = id and @qno = qno;
	end

-- trigger2
-- 判断触发器,如果存在则删除
IF (EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'Grade_update_trig') AND OBJECTPROPERTY(id, N'IsTrigger') = 1))
DROP TRIGGER Grade_update_trig;

--修改成绩的触发器
create trigger Grade_update_trig on sc
	instead of update
as
	declare @sno char(10);
	declare @sname char(10);
	declare @cno char(10);
	declare @grade int;
	declare @pregrade int;
	-- 插入的学号，课程号，成绩
	select @sno = sno, @cno = cno, @grade = grade from inserted;
	-- 对应同学的姓名与原成绩
	select @sname = (select sname from student where sno = @sno);
	select @pregrade = (select grade from sc where @cno = cno and @sno = sno);
	-- 表中该同学次门课已有成绩且修改成绩与原成绩不同
	if @pregrade is not null and @pregrade != @grade
	-- 打印出修改同学的姓名，学号，改后分数
	begin
		print '您要将'+convert(char,@sname)+convert(char,@sno)+'的原成绩'+convert(char,@pregrade)+'修改为'+convert(char,@grade);
		update sc
		set grade = @grade
		where @cno = cno and @sno = sno
	end

-- trigger3
-- 判断触发器,如果存在则删除
IF (EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'Ans_update_trig') AND OBJECTPROPERTY(id, N'IsTrigger') = 1))
DROP TRIGGER Ans_update_trig;
-- 上传学生答案的触发器（如果重复上传则回滚并提醒）【一个表的同种类型触发器只能有一个，根据情况可以使用trigger4】
create trigger Ans_update_trig on answer
	instead of insert
as
	declare @sno char(10)
	declare @cno char(10)
	declare @qno int
	declare @id int
	declare @aid char(10)
	declare @ans char(20)
	-- 插入的课程号，作业号，题号，标准答案
	select @sno = sno from inserted
	select @cno = cno from inserted
	select @id = id from inserted
	select @aid = aid from inserted
	select @qno = qno from inserted
	-- 如果标准答案不为空，即已有标准答案
	if ((select ans from answer where @sno = sno and @cno = cno and @aid = aid) is not null)
	begin
		-- 打印提示指令
		print '请更新作业提交次数，重新提交答案' 
	end

-- 实验代码
select * from course;
select * from question;
select * from sc;
select * from answer;
insert into question(cno,qno,id,std_ans) values('100','1','1','1')
insert into question(cno,qno,id,std_ans) values('100','1','1','2')
insert into sc(sno,cno,grade) values('2020200003','100','95')
insert into sc(sno,cno,grade) values('2020200004','100','96')
insert into sc(sno,cno,grade) values('2020200003','100','96')
update sc set grade = 96
where sno = '2020200003' and cno = '100';
insert into answer(sno,cno,qno,id,aid,ans) values('2020200003','100','1','1',NULL,'1')
insert into answer(sno,cno,qno,id,aid,ans) values('2020200003','100','1','1',NULL,'2')
insert into answer(sno,cno,qno,id,aid,ans) values('2020200003','100','1','2',NULL,'2')
insert into answer(sno,cno,qno,id,aid,ans) values('2020200003','100','1','2',NULL,'1')

-- trigger4
-- 判断触发器,如果存在则删除
IF (EXISTS(SELECT * FROM sysobjects WHERE id=object_id(N'Ans_aid_update_trig') AND OBJECTPROPERTY(id, N'IsTrigger') = 1))
DROP TRIGGER Ans_aid_update_trig;
-- 上传学生答案的触发器（提交次数无所谓，可以查询最后一次提交，并在基础上自动+1作为aid）
create trigger Ans_aid_update_trig on answer
	instead of insert
as
	declare @sno char(10)
	declare @cno char(10)
	declare @qno int
	declare @id int
	declare @aid char(10)
	declare @ans char(20)
	-- 插入的课程号，作业号，题号，标准答案
	select @sno = sno from inserted
	select @cno = cno from inserted
	select @id = id from inserted
	--select @aid = aid from inserted
	select @qno = qno from inserted
	select @ans = ans from inserted
	--找出当前课程号作业号中最大的提交次数并+1，作为这一次的提交次数
	select @aid = (select count(aid) from answer where @sno = sno and @cno = cno and @qno = qno and @id = id)
	-- 打印提示指令
	print '这是您本次作业的第'+convert(char,@aid+1)+'次尝试'
	-- 插入答案，提交次数为@aid+1
	insert into answer(sno, cno, qno, id, aid, ans) values (@sno, @cno, @qno, @id, @aid+1, @ans)
	
