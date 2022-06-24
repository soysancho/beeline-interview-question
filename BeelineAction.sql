-- Скрипт для нахождения количества шансов для участия в акции от Билайн,
-- т.е. сколько раз сможет участвовать в акции клиентов, заплативший N-ую сумму
-- *** Условия акции: за каждые 20 тысяч сум клиент получает 1 шанс ***
-- Например, 60 т. сум = 3 шанса, 45 т. сум = 2 шанса, 10 т. сум = естественно, 0 шансов
/*
---------------------------------------------------------------------
------------------------- ПОДГОТОВКА ДАННЫХ -------------------------
---------------------------------------------------------------------
drop table if exists BeelineAction

create table BeelineAction (
	[CustomerID] int identity(1,1) Primary Key,
	[Name] varchar(max),
	[Paid] money,
	[Date] datetime
)

set identity_insert beelineaction off

insert into BeelineAction ([Name], [Paid], [Date]) values
('Sanjar', 50000, '2022-04-05 10:31:12.247'),
('Svetlana', 60000, '2022-08-05 15:13:26.423'),
('Tatyana', 30000, '2022-14-05 20:09:14.371'),
('Andrey', 10000, '2022-24-05 06:47:52.705'),
('Boris', 100000, '2022-25-05 14:21:47.354')
---------------------------------------------------------------------
--------------------------- СОЗДАНИЕ ВИДа ---------------------------
---------------------------------------------------------------------
drop view if exists ChanceAmount
create view ChanceAmount as
(
select customerid, name, paid, date, cast(FLOOR(Paid/20000) as int) as [total chances]
from BeelineAction
)
select *					-- ПРОВЕРКА ТОГО, КТО СКОЛЬКО ЗАПЛАТИЛ
from ChanceAmount			-- И СКОЛЬКО ШАНСОВ ИМЕЕТ
*/
---------------------------------------------------------------------
------------------- ПОЛУЧЕНИЕ НУЖНОГО РЕЗУЛЬТАТА --------------------
---------------------------------------------------------------------
-------- ЗАПУСТИТЬ ОДНОВРЕМЕННО СТРОКИ 44-82 ИЛИ НАЖАТЬ F5  ---------
---------------------------------------------------------------------
------------------------------ НАЧАЛО -------------------------------
declare @ActionParticipants table (CustomerID int, Name varchar(max), Chance int)
declare @TotalChances int = (select sum(cast(FLOOR(Paid/20000) as int)) as [total chances]
						from BeelineAction)
declare @idcntr int = 1
declare @prtcpntcntr int = 1
if ((select [total chances] from ChanceAmount where customerid = @idcntr) > 0)
begin
while (@prtcpntcntr <= @TotalChances)
begin
	while (@idcntr <= (select count(customerid) from BeelineAction))
	begin
		with ActionMembers (CustomerID, Name, Chances) as
		(
		select CustomerID as [uchastnik akcii], Name, 1
		from ChanceAmount
		where customerid = @idcntr
		union all
		select c.CustomerID, c.Name, Chances+1
		from ChanceAmount c
		join ActionMembers a
		on c.Name = a.Name
		where Chances < (select cast(FLOOR(Paid/20000) as int) as [chances]
							from BeelineAction
							where CustomerID = @idcntr)
		)
		insert into @ActionParticipants
		select CustomerID, Name, 1
		from ActionMembers
		where (select [total chances] from ChanceAmount where customerid = @idcntr) > 0
		set @idcntr = @idcntr+1
	end;
	set @prtcpntcntr = @prtcpntcntr+1
end;
set @prtcpntcntr = @prtcpntcntr+1
end;
select Name as [Имя], Chance as [Шанс]
		,count(Chance) over(partition by Name) as [Всего шансов]
from @ActionParticipants
order by count(Chance) over(partition by Name)
------------------------------ КОНЕЦ -------------------------------
--------------------------------------------------------------------