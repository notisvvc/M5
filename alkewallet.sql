CREATE DATABASE alkewallet;


-- creación de tablas

CREATE TABLE usuario(
	user_id SERIAL PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	correo_electronico VARCHAR(50) NOT NULL UNIQUE,
	contrasena VARCHAR(50) NOT NULL,
	saldo NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (saldo >= 0)
);

CREATE TABLE moneda (
	currency_id SERIAL PRIMARY KEY,
	currency_name VARCHAR(50) NOT NULL UNIQUE,
	currency_symbol VARCHAR(10)NOT NULL,
	factor_to_clp 
);

CREATE TABLE transaccion(
	transaccion_id SERIAL PRIMARY KEY,
	sender_user_id INT NOT NULL
		REFERENCES usuario (user_id)
		ON DELETE CASCADE,
	receiver_user_id INT NOT NULL
		REFERENCES usuario (user_id)
		ON DELETE CASCADE,
	currency_id INT NOT NULL
		REFERENCES moneda(currency_id)
		ON DELETE CASCADE,
	importe NUMERIC(14,2) NOT NULL
		CHECK(importe > 0),
	factor_to_clp_usado DECIMAL(10,5)
		NOT NULL CHECK(factor_to_clp_usado > 0),
	importe_clp NUMERIC(14,2) NOT NULL
		CHECK(importe_clp > 0),
	transaction_date TIMESTAMP NOT NULL DEFAULT NOW(),

	CHECK (sender_user_id <> receiver_user_id) 
);

-- insercion de datos

INSERT INTO usuario (nombre, correo_electronico, contrasena, saldo) VALUES
('Ana Pérez', ' ana.perez@correo.cl', ' has123', 500000),
('Juan Soto', ' juan.soto@correo.cl', ' has123', 500000),
('María López', 'maria.lopez@correo.cl', ' has123', 500000),
('Pedro González', 'pedro.gonzalez@correo.cl', ' has123', 500000),
('Lucía Torres', 'lucia.torres@correo.cl', ' has123', 500000),
('Carlos Rojas', 'carlos.rojas@correo.cl', ' has123', 500000),
('Daniela Fuentes', 'daniela.fuentes@correo.cl', ' has123', 500000),
('Miguel Diaz', 'miguel.diaz@correo.cl', ' has123', 500000),
('Paula Herrera', 'paula.herrera@correo.cl', ' has123', 500000),
('Jorge Molina', 'jorge.molina@correo.cl', ' has123', 500000),
('Valentina Cruz', 'valentina.cruz@correo.cl', ' has123', 500000),
('Andrés Silva', 'andres.silva@correo.cl', ' has123', 500000),
('Camila Reyes', 'camila.reyes@correo.cl', ' has123', 500000),
('Sebastián Pino', 'sebastian.pino@correo.cl', ' has123', 500000),
('Fernanda Vega', 'fernanda.vega@correo.cl', ' has123', 500000),
('Rodrigo Munoz', 'rodrigo.munoz@correo.cl', ' has123', 500000),
('Constanza Leon', 'consta@correo.cl', ' has123', 500000),
('Tomas Araya', '@correo.cl', ' has123', 500000),
('Natalia Campos', '@correo.cl', ' has123', 500000),
('Felipe Navarro', '@correo.cl', ' has123', 500000),

INSERT INTO transaccion (
	sender_user_id,
	receiver_user_id,
	currency_id,
	importe,
	factor_to_clp_usado,
	importe_clp
) VALUES

--1) Ana a Juan : 50.000 CLP
(1, 2, 1, 50000, 1, 50000),

--2) maria a pedro : 10 USD = 8.630 CLP
(3, 4, 2, 10, 863, 8630),

--3) carlos a lucia : 5 EUR = 5.125 CLP
(6, 5, 3, 5, 1025, 5125),

--4) jorge a paula : 100 USD = 86.300 CLP
(10, 9, 2, 100, 863, 86300),

--5) fernanda a tomas : 20 EUR = 20.500 CLP
(15, 18, 3, 20, 1025, 20500);


-- TRANSACCION transferir de maria a pedro 20 USD

BEGIN
-- codigo para bloquear a usuarios involucrados
select nombre, saldo from usuario
where user_id in (3,4)
FOR UPDATE;

-- calculo de monto en CLP a transferir

select factor_to_clp, 20*factor_to_clp as importe_clp
from moneda where currency_id = 2;

-- registrar la transaccion

INSERT INTO transaccion(
	sender_user_id,
	receiver_user_id,
	currency_id,
	importe,
	factor_to_clp_usado,
	importe_clp
) VALUES (
	3,
	4,
	2,
	20,
	863,
	17260
)

-- descontar saldo a emisor 

UPDATE usuario
SET saldo = saldo - 17260
where user_id = 3;

-- sumar saldo al receptor

UPDATE usuario
SET saldo = saldo + 17260
where user_id = 4;

COMMIT

select nombre, saldo from usuario
where user_id in (3,4);


-- consultas a BBDD

-- 1) consulta a user especifico

select * from
usuario u
join
transaccion t
on u.user_id = t.sender_user_id
join
moneda m
on m.currency_id = t.currency_id
where t.sender_user_id = 3;

--2 ) log global

select * from transaccion;

--3 ) log global con nombres

select
	t.transaccion_id,
	t.transaction_date,
	u_sender.user_id as id_emisor,
	u_sender.nombre as emisor,
	u_receiver.user_id as id_receptor,
	u_receiver.nombre as receptor,
	m.currency_symbol as moneda,
	t.importe, t.importe_clp, t.factor_to_clp_usado
from transaccion t
inner join usuario u_sender on u_sender.user_id = t.sender_user_id
inner join usuario u_receiver on u_receiver.user_id = t.receiver_user_id
inner join moneda m on m.currency_id = t.currency_id
order by t.transaction_date desc;

--4 ) log personal con nombre (ana)

select
	t.transaccion_id,
	t.transaction_date,
	u_sender.user_id as id_emisor,
	u_sender.nombre as emisor,
	u_receiver.user_id as id_receptor,
	u_receiver.nombre as receptor,
	m.currency_symbol as moneda,
	t.importe, t.importe_clp, t.factor_to_clp_usado
from transaccion t
inner join usuario u_sender on u_sender.user_id = t.sender_user_id
inner join usuario u_receiver on u_receiver.user_id = t.receiver_user_id
inner join moneda m on m.currency_id = t.currency_id
where t.sender_user_id = 1
order by t.transaction_date desc;

--5 ) total de transacciones por usuario (envio)

select
	u_sender.user_id, u_sender.nombre, count(u_sender.user_id)
from transaccion t
inner join usuario u_sender on u_sender.user_id = t.sender_user_id
inner join moneda m on m.currency_id = t.currency_id
GROUP BY u_sender.user_id;

--6 ) total de transacciones por usuario (recepcion)

select
	u_receiver.user_id, u_receiver.nombre, count(u_receiver.user_id)
from transaccion t
inner join usuario u_receiver on u_receiver.user_id = t.receiver_user_id
inner join moneda m on m.currency_id = t.currency_id
GROUP BY u_receiver.user_id;

-- crear vista

CREATE VIEW vw_top_usuarios AS
SELECT user_id, nombre, correo_electronico, saldo
FROM usuario
ORDER BY saldo DESC
LIMIT 5;

select * from vw_top_usuarios;