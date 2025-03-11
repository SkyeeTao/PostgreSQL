------------------------------------------------------
-- COMP9311 24T1 Project 1 
-- SQL and PL/pgSQL 
-- Template
-- Name: Skye Tao
-- zID: z5285195
------------------------------------------------------

-- Q1:
create or replace view Infoschool 
as
select u.id
from orgunits u
join orgunit_types t on u.utype = t.id
where u.longname like '%Information%' and t.name like '%School%';

create or replace view Q1(subject_code)
as
select s.code
from subjects s, Infoschool i
where s.offeredby = i.id and s.code like '____7%';

-- Q2:
create or replace view COMP
as
select c.id
from courses c
join subjects s on s.id = c.subject
where s.code like 'COMP%';

create or replace view Leclab
as
select c.id 
from courses c
join classes cla on c.id = cla.course
join class_types ctp on cla.ctype = ctp.id
group by c.id 
having count(distinct cla.ctype) = 2
and bool_and(ctp.name in ('Lecture', 'Laboratory')); 

create or replace view Q2(course_id)
as
select c.id
from courses c
join COMP cp on c.id = cp.id
join Leclab ll on c.id = ll.id;

-- Q3:

create or replace view Profs
as 
select cs.course, count(*) as num_profs
from course_staff cs
join people p on cs.staff = p.id
where p.title like 'Prof'
group by cs.course
having count(*) >= 2;

create or replace view Enrolgret5
as 
select ce.student, count(*) as num_courses
from course_enrolments ce
join courses c on ce.course = c.id
join semesters s on c.semester = s.id
group by ce.student
having count(*) >= 5
and min(s.year) >= 2008
and max(s.year) <= 2012;

create or replace view Cpe
as 
select er.student
from Enrolgret5 er
join course_enrolments ce on er.student = ce.student
join Profs pro on ce.course = pro.course
group by er.student
having count(distinct case when pro.num_profs >= 2 then ce.course end) >= 5;

create or replace view Q3(unsw_id)
as
select ple.unswid
from people ple
join  Cpe cpe on ple.id = cpe.student
where CAST(ple.unswid as text) like '320%';


-- Q4:
create or replace view Avgmark
as
select c.id as course_id, o.id as faculty_id, s.id as semester_id, round(avg(ce.mark), 2) as average_mark
from course_enrolments ce
join courses c on ce.course = c.id
join subjects sj on c.subject = sj.id
join semesters s on c.semester = s.id
join orgunits o on sj.offeredby = o.id
join orgunit_types ot on o.utype = ot.id
where ot.name like 'Faculty' and s.year = 2012 and ce.grade in ('HD', 'DN')
group by c.id, o.id, s.id;

create or replace view Maxavgmark
as
select faculty_id, semester_id, max(average_mark) as avg_mark
from Avgmark
group by faculty_id, semester_id;

create or replace view Q4(course_id, avg_mark)
as
select ag.course_id, mag.avg_mark
from Avgmark ag
join Maxavgmark mag on ag.faculty_id = mag.faculty_id and ag.semester_id = mag.semester_id and ag.average_mark = mag.avg_mark;


-- Q5:
create or replace view Checker
as
select ce.course, count(*) as num_students
from course_enrolments ce
join courses c on ce.course = c.id
join semesters s on c.semester = s.id
group by ce.course
having count(*) >= 500
and min(s.year) >= 2005
and max(s.year) <= 2015;

create or replace view Staff_profs
as
select cs.course, count(*) as num_profs
from course_staff cs
join people p on cs.staff = p.id
where p.title like 'Prof'
group by cs.course
having count(*) >= 2;

create or replace view Q5(course_id, staff_name)
as
select cs.course, STRING_AGG(p.given, '; ' order by p.given) as staff_name
from course_staff cs
join people p on cs.staff = p.id
join Checker ce on cs.course = ce.course
join Staff_profs sp on cs.course = sp.course
where p.title like 'Prof'
group by cs.course
order by staff_name;

-- Q6:
create or replace view Classes_usage 
as
select r.id, count(distinct cla.id) as class_usage
from rooms r
join classes cla on r.id = cla.room
join courses c on cla.course = c.id
join semesters s on c.semester = s.id
where s.year = 2012
group by r.id;

create or replace view Max_room
as
select id
from Classes_usage
where class_usage = (select max(class_usage) from Classes_usage);

create or replace view Room_subcode
as
select r.id, sj.code, count(distinct cla.id) as sub_usage
from rooms r
join classes cla on r.id = cla.room
join courses c on cla.course = c.id
join semesters s on c.semester = s.id
join subjects sj on c.subject = sj.id
where s.year = 2012
group by r.id, sj.code;

create or replace view Max_sub_count
as
select id, max(sub_usage) as max_sub_usage
from Room_subcode
group by id;

create or replace view Max_subcode
as
select rsc.id, rsc.code
from Room_subcode rsc
join Max_sub_count msc on rsc.id = msc.id and rsc.sub_usage = msc.max_sub_usage;

create or replace view Q6(room_id, subject_code) 
as
select mr.id, msc.code
from Max_room mr
join Max_subcode msc on mr.id = msc.id;

-- Q7:
create or replace view Copass
as
select ce.student, ce.course, c.semester, c.subject, ce.mark
from courses c
join course_enrolments ce on ce.course = c.id
join subjects sj on sj.id = c.subject
where ce.mark >= 50;

create or replace view Proguoc
as
select co.student, pe.program, sum(sj.uoc) as count_uoc, min(s.starting) as prog_start, max(s.ending) as prog_end
from program_enrolments pe
join Copass co on co.student = pe.student and pe.semester = co.semester
join subjects sj on co.subject = sj.id
join semesters s on co.semester = s.id
group by co.student, pe.program;

create or replace view Checkprog
as
select pgc.student, pgc.program, pgc.prog_start, pgc.prog_end
from Proguoc pgc
join programs p on p.id = pgc.program
where pgc.count_uoc >= p.uoc; 

create or replace view Progperiod
as
select cpg.student, o.id as orgid, count(distinct cpg.program) as finish_prog, min(cpg.prog_start) as startdate, max(cpg.prog_end) as enddate
from Checkprog cpg
join programs p on p.id = cpg.program
join orgunits o on p.offeredby = o.id
group by cpg.student, o.id
having max(cpg.prog_end) - min(cpg.prog_start) <= 1000;

create or replace view Q7(student_id, program_id) 
as
select ppl.unswid, cpg.program
from people ppl
join Progperiod ppd on ppd.student = ppl.id
join Checkprog cpg on cpg.student = ppd.student
where ppd.finish_prog >= 2;

-- Q8:
create or replace view Convenor
as
select cst.staff, ce.course
from course_staff cst
join staff_roles sr on sr.id = cst.role
join course_enrolments ce on ce.course = cst.course
join courses c on ce.course = c.id
join semesters s on s.id = c.semester
where s.year = 2012 and sr.name like 'Course Convenor'
group by cst.staff, ce.course;

create or replace view Ehdn
as
select cov.staff, cov.course, count(*) filter (where ce.mark is not null) as total_stds, count(*) filter (where ce.mark >= 75) as distinct_stds
from Convenor cov
join course_enrolments ce on ce.course = cov.course
group by cov.staff, cov.course;

create or replace view Hdnr
as
select eh.staff, round(sum(eh.distinct_stds) * 1.0 / NULLIF(sum(eh.total_stds), 0), 2) as hdn_rate
from Ehdn eh
group by eh.staff;

create or replace view sumroles
as 
select a.staff, count(*) as sum_roles
from affiliations a
group by a.staff;

create or replace view sameorg
as
select sr.staff, a.orgunit, count(*) as roles
from sumroles sr
join affiliations a on a.staff = sr.staff
join orgunits o on o.id = a.orgunit 
group by sr.staff, a.orgunit
having count(*) >= 3;

create or replace view Q8 as
with Rankhdn as (
    select ppl.unswid as staff_id,
           sr.sum_roles,
           hd.hdn_rate,
           rank() over (order by hd.hdn_rate desc, sr.sum_roles desc) as rn
    from people ppl
    join Hdnr hd on hd.staff = ppl.id
    join sumroles sr on sr.staff = ppl.id
    join (select distinct staff from sameorg) as sg on sg.staff = ppl.id
)
select staff_id, sum_roles, hdn_rate
from Rankhdn
where rn <= 20;


-- Q9
create or replace view Sameprefix
as
select c.id as course_id, s.code as subject_code
from courses c
join subjects s on s.id = c.subject
where s._prereq is not null
and position(substr(s.code, 1, 4) in s._prereq) > 0;

create or replace view Markvalid
as
select spf.course_id, spf.subject_code, ce.student, ce.mark
from Sameprefix spf
join course_enrolments ce on ce.course = spf.course_id
where ce.mark is not null;

create or replace view Rankcheck
as
select course_id, subject_code, student, mark,
rank() over (PARTITION by course_id order by mark DESC) as rank
from Markvalid mv;


create or replace function 
	Q9(unswid integer)  returns setof text
as $$
begin
	if not exists(
		select 1
		from Rankcheck rc
		join people p on p.id = rc.student
		where p.unswid = Q9.unswid
	) 	then
		return Next 'WARNING: Invalid Student Input [' || unswid || ']';
	else 
		return query
		SELECT rc.subject_code || ' ' || CAST(rc.rank AS TEXT) as result
		from Rankcheck rc
		join people p on rc.student = p.id
		where p.unswid = Q9.unswid;
	end if;
end;
$$ language plpgsql;

-- Q10
create or replace function 
	Q10(unswid integer) returns setof text
as $$
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

