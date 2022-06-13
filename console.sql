--trial data grip version 2021.2.2 (ide с удобными мне подсказками, и т.к. это последняя версия без логина и пароля jet brains)
-- Oracle Express Edition 18c

--создание таблиц
create table x#user
(
    id    number GENERATED ALWAYS AS IDENTITY not null primary key, --идентификатор гражданина
    c_fio varchar2(100) not null              --ФИО гражданина - формат строки: фамилия, имя, отчество через запятую
);

/*
drop table x#user_on_address;
drop table x#user;
drop table x#address;
*/

create table x#address
(
    id        number GENERATED ALWAYS AS IDENTITY not null primary key, --идентификатор адреса прописки
    c_address varchar2(300) not null     --формат адреса: город, улица, дом, квартира, почтовый индекс в указанном порядке через запятую

);

create table x#user_on_address
(
    id        number GENERATED ALWAYS AS IDENTITY not null primary key, --идентификатор прописки
    c_user    number not null,             --идентификатор гражданина
    c_address number not null,             --идентификатор адреса прописки
    c_begin   date   not null,             --дата прописки
    c_end     date,             --дата выписки

    constraint fk_user foreign key (c_user) references x#user(id),
    constraint fk_address foreign key (c_address) references x#address(id)
);

--создание типа данных набора строк (ассоциативный массив)
CREATE TYPE string_array AS table of varchar2(1000);

--функция для создания набора строк из строки с разделителями
CREATE OR REPLACE FUNCTION split(p_list IN varchar2, delimiter IN varchar2 DEFAULT ',')
    RETURN string_array
AS
    l_string      varchar2(32767) := p_list || delimiter;
    l_comma_index pls_integer;
    l_index       pls_integer     := 1;
    l_tab         string_array    := string_array();
BEGIN
    LOOP
        l_comma_index := INSTR(l_string, delimiter, l_index);
        EXIT WHEN l_comma_index = 0;
        l_tab.extend;
        l_tab(l_tab.count) := SUBSTR(l_string, l_index, l_comma_index - l_index);
        l_index := l_comma_index + 1;
    END LOOP;
    RETURN l_tab;
END split;

--вспомогательная функция, формирующая случайное число в заданном диапазоне
create or replace function random_value(from_value number, to_value number) return number as
    rnd number;
begin
    rnd := trunc(dbms_random.value(from_value, to_value + 1));
--     dbms_output.put_line(rnd);
    return rnd;
end random_value;


-- 1 задание
-- создание object_type для манипуляций над полем с адресом и индексом
CREATE OR REPLACE type first_task_type as object
(
    fio     varchar2(300),
    address varchar2(300),
    zip     varchar2(6)
);
create or replace type first_task_table is table of first_task_type;


-- заполнение полей не удалось, ошибка "not enough values"
create OR replace PROCEDURE first_task(p_mode number)
-- temp ...
AS
begin
    if p_mode = 0
    then
        select u.c_fio,
               substr(a.c_address, 1, instr(a.c_address, ',', 1, 4) - 1),
               substr(a.c_address, instr(a.c_address, ',', 1, 4) + 1, length(a.c_address))
        --into temp ...
        from x#user_on_address ua
                 join x#user u on u.id = ua.c_user
                 join x#address a on a.id = ua.c_address
        where ua.id in (select max(ua.id)
                        from x#user_on_address ua
                        group by ua.c_user
        );
    elsif p_mode = 1 then
        select u.c_fio,
               substr(a.c_address, 1, instr(a.c_address, ',', 1, 4) - 1)                   AS "Действующий адрес",
               substr(a.c_address, instr(a.c_address, ',', 1, 4) + 1, length(a.c_address)) AS "Действующий индекс"
        --into temp ...
        from x#user_on_address ua
                 join x#user u on u.id = ua.c_user
                 join x#address a on a.id = ua.c_address
        where ua.id in (select max(ua.id)
                        from x#user_on_address ua
                        group by ua.c_user
        )
          and ua.c_end is null;
    elsif p_mode = -1 then --допустим, имеются в виду и без адреса вообще, и выписанные (c_end is not null)
        select u.c_fio
        --into temp ...
        from x#user u
        where not exists(select 1
                         from x#user_on_address ua
                         where u.id = ua.c_user)
        union
        select u.c_fio
        --into temp ...
        from x#user_on_address ua
                 join x#user u on u.id = ua.c_user
        where ua.c_end is not null;
    end if;
END first_task;

begin
    select * from first_task(1);
end;


-- 2 задание
CREATE OR REPLACE function alphavite
    return varchar2
AS
    string varchar2(26) := '';
BEGIN
    for code in 97 .. 122
        LOOP
            string := string || chr(code);
        END LOOP;
    RETURN string;
END alphavite;

SELECT alphavite()
FROM dual;


--3 задание
--создание типа объекта (record), который предстоит делить
CREATE OR REPLACE type key_value_pair as object
       (
           key   number,
           value varchar2(100)
       );

create type key_value_pair_array is table of key_value_pair;

--сплит-функция, разделяющая заданную record
create or replace function split_string_task
    return key_value_pair_array
AS
    array            key_value_pair_array := key_value_pair_array();
    splitted_string  string_array;
    splitted_string2 string_array;
    part             varchar2(100);
    value            varchar2(100);
    key              number;
BEGIN
    splitted_string := split('Аналитик:1#Разработчик:12#Тестировщик:10#Менеджер:3', '#');
    for i in splitted_string.first .. splitted_string.last
        loop
            part := splitted_string(i);
            splitted_string2 := split(part, ':');
            key := to_number(splitted_string2(2));
            value := splitted_string2(1);
            array.extend;
            array(i) := key_value_pair(key, value);
        end loop;
    return array;
END split_string_task;

select *
from split_string_task();

