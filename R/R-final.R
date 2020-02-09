
#### On Linux server:
#library(DBI)
#con <- dbConnect(odbc::odbc(), .connection_string = "Driver={ODBC Driver 17 for SQL Server};server=192.168.1.1;
#database=COLLEGE;uid=dsuser02;
#pwd=DSuser02!", timeout = 10)

#### On Windows:
library(DBI)
con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server Native Client 11.0};server=DESKTOP-4P3K6TB\\SQLEXPRESS01;Trusted_Connection=yes;", timeout = 10)
#get tables
library(dplyr)
sql <- "SELECT * FROM COLLEGE.dbo.Students"
students_df <- as_data_frame(dbGetQuery(con, sql))
students_df
sql1 <- "SELECT * FROM COLLEGE.dbo.Classrooms"
classrooms_df <- as_data_frame(dbGetQuery(con, sql1))
classrooms_df
sql2 <- "SELECT * FROM COLLEGE.dbo.Courses"
courses_df <- as_data_frame(dbGetQuery(con, sql2))
courses_df
sql3 <- "SELECT * FROM COLLEGE.dbo.Departments"
departments_df <- as_data_frame(dbGetQuery(con, sql3))
departments_df
sql4 <- "SELECT * FROM COLLEGE.dbo.Teachers"
teachers_df <- as_data_frame(dbGetQuery(con, sql4))
teachers_df
## Get the whole table:
#df <- dbReadTable(con, "COLLEGE.dbo.Classrooms")
#Create merged dataframes
co_cl <- inner_join(courses_df, classrooms_df, by = "CourseId")
co_cl_dep <- inner_join(co_cl,departments_df, c("DepartmentID" = "DepartmentId"))

## Questions

##############
## Q1. Count the number of students on each department¶
##############
dep_count <- unique(co_cl_dep %>% select (DepartmentName, StudentId))%>%
             group_by(DepartmentName) %>%
             tally()

names(dep_count)<-c("DepartmentName","NumOfStudents")

##############
## Q2. How many students have each course of the English department and the 
##     total number of students in the department?
##############

co_count_eng <- unique(co_cl_dep %>% 
                         filter(DepartmentID == 1) %>%
                         select (CourseName, StudentId))%>%
                group_by(CourseName) %>%
                tally()
names(co_count_eng) <- c("CourseName","NumOfStudents")


total_count_eng <- data.frame("Total", unique(co_cl_dep %>% 
                                      filter(DepartmentID == 1)%>%
                                      select (DepartmentName, StudentId)) %>%
                                      tally())
names(total_count_eng) <- c("CourseName","NumOfStudents")

co_count_eng_t <- rbind(co_count_eng, total_count_eng)


##############
## Q3. How many small (<22 students) and large (22+ students) classrooms are 
##     needed for the Science department?
##############

co_count_sci <- unique(co_cl_dep %>% 
                         filter(DepartmentID == 2) %>%
                         select (CourseName, StudentId))%>%
                group_by(CourseName) %>%
                tally()
names(co_count_sci)<-c("CourseName","NumOfStudents")
co_count_sci_s <- co_count_sci %>%
                  mutate(ClassroomSize = ifelse(NumOfStudents < 22 ,"Small","Big"))

co_sci_s <- co_count_sci_s %>%
            group_by(ClassroomSize) %>%
            tally()

##############
## Q4. A feminist student claims that there are more male than female in the 
##     College. Justify if the argument is correct
##############

gen <- students_df %>%
       group_by(Gender) %>%
       tally()

##############
## Q5. For which courses the percentage of male/female students is over 70%?
##############

co_cl_dep_st <- inner_join(co_cl_dep,students_df, by="StudentId")

gen_co <- co_cl_dep_st %>%
          select(CourseName, StudentId, Gender) %>%
          group_by(CourseName, Gender) %>%
          tally()
names(gen_co)<-c("CourseName","Gender", "NumOfStudents")

gen_co_t <- co_cl_dep_st %>%
            select(CourseName, StudentId) %>%
            group_by(CourseName) %>%
            tally()
names(gen_co_t)<-c("CourseName","TotalNumOfStudents")

gen_co_m1 <- left_join(gen_co_t, gen_co, by="CourseName")

gen_co_m2 <- gen_co_m1 %>%
             mutate(StudentsPercent = (NumOfStudents/TotalNumOfStudents) * 100 )

gen_co_m <- gen_co_m2 %>%
            select(CourseName, Gender, StudentsPercent) %>%
            filter(StudentsPercent > 70)

##############
## Q6. For each department, how many students passed with a grades over 80?
##############

dep_st_h_av <- co_cl_dep %>%
               select(DepartmentName, StudentId, Degree) %>%
               group_by(DepartmentName, StudentId) %>%
               summarise(MeanDegree = mean(Degree)) %>%
               filter(MeanDegree > 80) %>%
               group_by(DepartmentName) %>%
               tally()

##############
## Q7. For each department, how many students passed with a grades under 60?
##############

dep_st_l_av <- co_cl_dep %>%
               select(DepartmentName, StudentId, Degree) %>%
               group_by(DepartmentName, StudentId) %>%
               summarise(MeanDegree = mean(Degree)) %>%
               filter(MeanDegree < 60) %>%
               group_by(DepartmentName) %>%
               tally()

##############
## Q8. Rate the teachers by their average student's grades (in descending order).
##############

co_cl_dep_te <- left_join(co_cl_dep, teachers_df, by="TeacherId")

co_cl_dep_teacher <- co_cl_dep_te %>%
                     mutate("TeacherName" = paste (FirstName,LastName, sep = " ")) 

te_deg <- co_cl_dep_teacher %>% 
          select (TeacherName, StudentId,Degree) %>%
          group_by(TeacherName) %>%
          summarise(MeanDegree = mean(Degree)) %>%
          arrange(desc(MeanDegree))


##############
## Q9. Create a dataframe showing the courses, departments they are associated with, 
##     the teacher in each course, and the number of students enrolled in the course 
##     (for each course, department and teacher show the names).
##############
co_dep_l <- left_join(courses_df, departments_df, c("DepartmentID" = "DepartmentId"))
co_dep_cl_l <- left_join(co_dep_l, classrooms_df, by ="CourseId")
co_dep_cl_te_l <- left_join(co_dep_cl_l, teachers_df, by = "TeacherId") %>%
                  mutate("TeacherName" = paste (FirstName,LastName, sep = " "))


college_sum <- co_dep_cl_te_l %>% 
              select (CourseId, CourseName, DepartmentName, TeacherName, StudentId) %>%
              group_by(CourseId, CourseName, DepartmentName, TeacherName) %>%
              tally(!is.na(StudentId))

##############
## Q10. Create a dataframe showing the students, the number of courses they take, 
##      the average of the grades per class, and their overall average (for each student 
##      show the student name).
##############

st_cl <- left_join(students_df, classrooms_df, by ="StudentId") %>%
        mutate("StudentName" = paste (FirstName,LastName, sep = " "))

st_cl_cnt <- st_cl %>%
            select (StudentName, CourseId) %>%
            group_by(StudentName) %>%
            tally(!is.na(CourseId))

st_av <- st_cl %>%
        select (StudentName, Degree) %>%
        group_by(StudentName) %>%
        summarise(AvgDegree = mean(Degree))

st_cl_av <- st_cl %>%
           select (StudentName, CourseId, Degree) %>%
           group_by(StudentName, CourseId) %>%
           summarise(AvgCoDegree = mean(Degree))

library(reshape)

st_cl_av_piv <- cast(st_cl_av, StudentName ~ CourseId) %>%
                select_if(function(x) any(!is.na(x)))

student_sum1 <- left_join(st_cl_cnt, st_cl_av_piv, by ="StudentName")

student_sum <- left_join(student_sum1, st_av, by ="StudentName")
