/*1.Найдите количество вопросов, которые набрали больше 
300 очков или как минимум 100 раз были добавлены в «Закладки».*/

SELECT COUNT(*)
FROM stackoverflow.posts pt 
WHERE post_type_id = 1
  AND (score > 300 OR favorites_count >= 100);
  
  
/*2.Сколько в среднем в день задавали вопросов 
с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.*/

SELECT ROUND(avg(quantity),0)
FROM (SELECT COUNT(id) as quantity,
             creation_date::date
      FROM stackoverflow.posts
      WHERE post_type_id = 1
      GROUP BY creation_date::date
      HAVING CAST(creation_date AS date) between '2008-11-01' and '2008-11-18'
      ) AS dt;
	  
/*3.Сколько пользователей получили значки сразу
 в день регистрации? Выведите количество уникальных пользователей.*/
 
SELECT count(DISTINCT b.user_id)
FROM stackoverflow.badges b 
left join stackoverflow.users u ON u.id = b.user_id
WHERE u.creation_date::date = b.creation_date::date;

/*4.Сколько уникальных постов пользователя с именем 
Joel Coehoorn получили хотя бы один голос?*/

SELECT COUNT(*)
FROM (
    SELECT v.post_id,
           count(v.id) AS quantity
    FROM stackoverflow.posts  p
    JOIN stackoverflow.users  u on p.user_id = u.id
    JOIN stackoverflow.votes v on p.id = v.post_id
    WHERE u.display_name = 'Joel Coehoorn'
    GROUP BY v.post_id
    ) AS post;
	
/*5.Выгрузите все поля таблицы vote_types. 
Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке.
 Таблица должна быть отсортирована по полю id.*/
 
SELECT *,
       DENSE_RANK() OVER(ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id;

/*6.Отберите 10 пользователей, которые поставили больше всего голосов типа Close.
 Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов.
 Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.*/
 
SELECT user_id, count(vote_type_id) as vote
FROM stackoverflow.vote_types vt
LEFT JOIN stackoverflow.votes v ON vt.id = v.vote_type_id
WHERE vt.name = 'Close'
GROUP BY user_id
ORDER BY vote  DESC, user_id DESC
LIMIT 10;

/*7.Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.*/

SELECT *,
   DENSE_RANK() OVER (ORDER BY quantity DESC)
FROM (SELECT user_id,
       COUNT(id) AS quantity 
      FROM stackoverflow.badges
      WHERE CAST(creation_date AS date) BETWEEN '2008-11-15' AND '2008-12-15'
      GROUP BY user_id
      ORDER BY quantity DESC
      LIMIT 10) AS tb
ORDER BY quantity DESC, user_id;

/*8.Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.*/

SELECT title,
      user_id,
      score,
      ROUND(AVG(score) OVER(PARTITION BY user_id)) AS score_avg
FROM stackoverflow.posts
WHERE title IS NOT NULL
   AND score != 0;
   
/*9.Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков.
 Посты без заголовков не должны попасть в список.*/
 
SELECT title
FROM stackoverflow.posts p
join (SELECT user_id,
      COUNT(id) quant
      FROM stackoverflow.badges 
      GROUP BY user_id
      HAVING COUNT(id) > 1000) b 
ON p.user_id = b.user_id
WHERE p.title IS NOT NULL ;

/*10.Напишите запрос, который выгрузит данные о пользователях из США (англ. United States).
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.*/

SELECT id,
       views,
   CASE
       WHEN views>=350 THEN 1
       WHEN views<100 THEN 3
       ELSE 2
    END AS group
FROM stackoverflow.users
WHERE location LIKE '%United States%'
  AND views != 0;
  
/*11.Дополните предыдущий запрос. 
Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.*/

WITH  cte as
(SELECT id,
       views,
   CASE
       WHEN views>=350 THEN 1
       WHEN views<100 THEN 3
       ELSE 2
    END AS "group"
FROM stackoverflow.users
WHERE location LIKE '%United States%'
  AND views != 0),
cte_b AS  
(SELECT 
       "group",
       MAX(views) AS max_views
 FROM cte
 GROUP BY "group")
 
SELECT c.id, cb."group", views
FROM cte c
JOIN cte_b cb ON c.views = cb.max_views
ORDER BY views DESC, id;

/*12.Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. 
Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением.*/

SELECT *,
     SUM(quant) OVER (ORDER BY dt) AS summa
FROM (SELECT EXTRACT(DAY FROM creation_date) as dt,
        COUNT(id) AS quant
      FROM stackoverflow.users
      WHERE DATE_TRUNC('MONTH', creation_date::date) = '2008-11-01'
      GROUP BY EXTRACT(DAY FROM creation_date)) AS tb;
	  
/*13.Для каждого пользователя, который написал хотя бы один пост, 
найдите интервал между регистрацией и временем создания первого поста. 
Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.*/

WITH cte AS
(
SELECT p.user_id,
    p.creation_date AS dt_p,
    u.creation_date AS dt_u,
    row_number() over (partition by user_id order by p.creation_date) as date_post   
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id = u.id
)

SELECT user_id,
       dt_p - dt_u
FROM cte
where date_post = 1;

/*14.Выведите общую сумму просмотров постов за каждый месяц 2008 года.
 Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
 Результат отсортируйте по убыванию общего количества просмотров.*/
 
SELECT CAST(DATE_TRUNC ('MONTH', creation_date) AS date),
       SUM(views_count) AS total
FROM stackoverflow.posts
GROUP BY  CAST(DATE_TRUNC ('MONTH', creation_date) AS date)
ORDER BY total DESC;

/*15.Выведите имена самых активных пользователей, которые в первый месяц после регистрации 
(включая день регистрации) дали больше 100 ответов. 
Вопросы, которые задавали пользователи, не учитывайте.
 Для каждого имени пользователя выведите количество уникальных значений user_id.
 Отсортируйте результат по полю с именами в лексикографическом порядке.*/
 
with cte as

(SELECT p.id,
       u.creation_date as regist_dt,
       p.creation_date as post_dt,
       p.user_id,
       display_name,
       post_type_id,
       cast(u.creation_date + interval '1 month' as date) as intrvel_data
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id = u.id
WHERE post_type_id = 2)

select display_name,
     count(distinct user_id)
from cte
where post_dt::date between regist_dt::date and intrvel_data
group by display_name
having count(id) > 100
order by display_name;

/*16.Выведите количество постов за 2008 год по месяцам. 
Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года 
и сделали хотя бы один пост в декабре того же года.
Отсортируйте таблицу по значению месяца по убыванию.*/

WITH CTE AS 
(SELECT DISTINCT user_id
FROM stackoverflow.users u
JOIN stackoverflow.posts p  ON u.id = p.user_id
WHERE CAST(u.creation_date AS date) between '2008-09-01' and '2008-09-30'
  and CAST(p.creation_date AS date) between '2008-12-01' and '2008-12-31')



SELECT CAST(DATE_TRUNC('MONTH', P.creation_date) AS date) as month_post,
       COUNT(P.id)
FROM stackoverflow.posts P
JOIN CTE C ON P.user_id = C.user_id
GROUP BY CAST(DATE_TRUNC('MONTH', P.creation_date) AS date)
ORDER BY month_post DESC;

/*17.Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, 
а данные об одном и том же пользователе — по возрастанию даты создания поста.*/

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER(PARTITION BY user_id  ORDER BY creation_date) AS sum_total
FROM stackoverflow.posts
ORDER BY user_id, creation_date;

/*18.Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост.
 Нужно получить одно целое число.*/
 
SELECT round(avg(day_quanity))
FROM(
SELECT user_id,
       COUNT(distinct CAST(creation_date AS date)) as day_quanity
FROM stackoverflow.posts
WHERE CAST(creation_date AS date) between '2008-12-01' and '2008-12-07'
GROUP BY user_id) AS CTE;

/*19.На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? 
Отобразите таблицу со следующими полями:
номер месяца;
количество постов за месяц;
процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. 
Чтобы этого избежать, переведите делимое в тип numeric.*/

WITH cte AS
(SELECT EXTRACT('MONTH' FROM CAST(creation_date AS date)) AS month_number,
       COUNT(id) AS total
FROM stackoverflow.posts
WHERE CAST(creation_date AS date) between '2008-09-01' AND '2008-12-31'
GROUP BY EXTRACT('MONTH' FROM CAST(creation_date AS date)))

SELECT *,
      round(((total::NUMERIC/LAG(total) OVER(ORDER BY month_number)) - 1) * 100, 2)
FROM cte;

/*20.Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время. 
Выведите данные за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.*/

WITH cte AS 
(
SELECT user_id,
       COUNT(DISTINCT id) AS quantity
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY quantity DESC
LIMIT 1),

     cte1 AS 
(
SELECT p.user_id,
       p.creation_date,
       extract('week' from p.creation_date) AS week_number
FROM stackoverflow.posts AS p
JOIN cte c ON c.user_id = p.user_id
WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01')

SELECT DISTINCT week_number::numeric,
       MAX(creation_date) OVER (PARTITION BY week_number)
FROM cte1
ORDER BY week_number;



 