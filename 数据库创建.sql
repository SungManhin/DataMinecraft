-- 如已存在则删除，初始化时使用，可以直接删除原有SCT数据库，如原环境中SCT数据库存在重要请转移后使用
IF  (EXISTS (SELECT * FROM dbo.sysdatabases where name=N'SCT')) DROP DATABASE SCT;

-- 创建数据库
create database SCT
on primary
(
  name=SCT,
  filename='D:\database\sql\file\SCT.mdf',
  size=100,
  maxsize=unlimited,
  filegrowth=10%
)
log on
(
  name=SCTlog,
  filename='D:\database\sql\file\SCTlog.ldf',
  size=50,
  maxsize=500,
  filegrowth=1
)

