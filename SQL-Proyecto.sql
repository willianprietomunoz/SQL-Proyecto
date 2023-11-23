CREATE DATABASE PRUEBA_NOMBRE_APELLIDO;

USE PRUEBA_NOMBRE_APELLIDO;

--Creacion tabla consumo
CREATE TABLE CONSUMO (
NumIdPersona int,
Periodo int not null,
Valor money not null,
NumTransacciones int not null,
UES varchar(30) null,
Producto varchar(30) null
);

--Importacion data consumo
BULK INSERT CONSUMO
FROM 'C:\Users\THINKPPLE\Downloads\Prueba BI Colsubsidio\Consumo 1.txt'
WITH (FIRSTROW =2
);

--Indexacion tabla consumo
CREATE CLUSTERED INDEX Ind_idPersona_Periodo ON CONSUMO (NumIdPersona,Periodo);


--Creacion tabla empresa
CREATE TABLE EMPRESA ( 
id_empresa int not null,
Piramide1 varchar(50) not null,
Piramide2 varchar(50) not null,
cx_empresa varchar(30) null,
cy_empresa varchar(30) null,
DepartamentoEmpresa varchar(50) null, 
MunicipioEmpresa varchar(50) null,
SectorCIIU varchar(100) not null,
DescripcionCIIU varchar(100) not null
constraint PK_empresa primary key (id_empresa)
);

--Importacion tabla empresa
BULK INSERT EMPRESA
FROM 'C:\Users\THINKPPLE\Downloads\Prueba BI Colsubsidio\Empresa 1.txt'
WITH (
	FIRSTROW = 2
);

--Indexacion tabla empresa
CREATE NONCLUSTERED INDEX Ind_idEmpresa_Piramides ON EMPRESA (id_empresa,Piramide1, Piramide2);


UPDATE EMPRESA
SET SectorCIIU = REPLACE(REPLACE(REPLACE(REPLACE(SectorCIIU, '¾', 'o'), '½', 'u'), '¼', 'a'), '·', 'n');

--Creacion tabla personas
CREATE TABLE PERSONAS (
NumIdPersona int not null,
id_empresa int not null,
Genero varchar(1) not null,
FechaNacimiento date not null,
Edad int not null,
Salario money not null,
Categoria varchar not null,
SegmentoPoblacional varchar (50) not null,
SegmetoGrupoFamiliar varchar(50) not null,
cx_persona varchar(50) null,
cy_persona varchar(50) null,
DepartamentoPersona varchar(100) null, 
MunicipioPersona varchar(100) null,
EstratoPersona int null,
constraint PK_personas primary key (NumIdPersona),
constraint FK_personas_empresa foreign key (id_empresa) references EMPRESA(id_empresa)
);

--Importacion tabla personas
BULK INSERT PERSONAS
FROM 'C:\Users\THINKPPLE\Downloads\Prueba BI Colsubsidio\Persona 1.txt'
WITH (
	FIRSTROW = 2
);

--Indexacion tabla empresa
CREATE NONCLUSTERED INDEX Ind_idPersona_IdEmpresa ON PERSONAS (NumIdPersona,Id_Empresa);

UPDATE PERSONAS
SET SegmentoPoblacional = REPLACE(SegmentoPoblacional, 'Bßsico', 'Basico')
WHERE SegmentoPoblacional LIKE '%Bßsico%';

SELECT * FROM CONSUMO;
SELECT * FROM EMPRESA;
SELECT * FROM PERSONAS;

--Periodos con ventas(Transacciones)
SELECT 
	DISTINCT (Periodo), 
	SUM(NumTransacciones) AS TotalTransacciones,
	SUM(Valor) AS ValorTotalTransacciones
FROM CONSUMO 
GROUP BY 
	PERIODO 
ORDER BY 
	TotalTransacciones 
DESC;


--Participacion consumo personas afiliadas y no afiliadas
SELECT 
	afiliacion, 
	COUNT(Afiliacion) AS TotalAfiliacion,
	100.0 * COUNT(Afiliacion) / SUM(COUNT(Afiliacion)) OVER () AS PorcentajeAfiliacion
FROM(SELECT 
		CONSUMO.NumTransacciones, 
		CONSUMO.Periodo, 
		PERSONAS.NumIdPersona,
	CASE WHEN PERSONAS.NumIdPersona IS NULL THEN 'No Afiliado' ELSE 'Afiliado' END AS Afiliacion
	FROM CONSUMO 
	LEFT JOIN PERSONAS 
	ON CONSUMO.NumIdPersona = PERSONAS.NumIdPersona) AS AFILIACION
GROUP BY 
	Afiliacion
ORDER BY
	PorcentajeAfiliacion DESC;


--Consumo total por unidad de nogocio
SELECT 
	DISTINCT (UES) AS UnidadDeNegocio,
	SUM(Valor) AS ConsumoTotal
FROM CONSUMO
WHERE UES IS NOT NULL
GROUP BY UES
ORDER BY ConsumoTotal DESC;


--Unidades de mayor uso por categoria
SELECT 
DISTINCT (UNIDADES.UES),
CATEGORIA_A.Categoria,
SUM(UNIDADES.CantidadTotalTransacciones) AS CantidadTransacciones
FROM
	(SELECT
	DISTINCT (NumIdPersona),
	Categoria
	FROM PERSONAS
	GROUP BY
	NumIdPersona,
	Categoria) AS CATEGORIA_A
LEFT JOIN
	(SELECT
	distinct NumIdPersona,
	UES,
	COUNT(UES) AS CantidadTrasaciones,
	SUM(NumTransacciones) AS CantidadTotalTransacciones
	FROM CONSUMO
	WHERE UES IS NOT NULL
	GROUP BY
	UES,
	NumIdPersona) AS UNIDADES 
ON CATEGORIA_A.NumIdPersona = UNIDADES.NumIdPersona
WHERE UES IS NOT NULL
GROUP BY 
	UNIDADES.UES,
	CATEGORIA_A.Categoria
ORDER BY
	CATEGORIA_A.Categoria ASC,
	CantidadTransacciones DESC;


--Producto de mayor uso por categoria
SELECT 
DISTINCT (UNIDADES.Producto),
CATEGORIA_A.Categoria,
SUM(UNIDADES.CantidadTotalTransacciones) AS CantidadTransacciones
FROM
	(SELECT
	DISTINCT (NumIdPersona),
	Categoria
	FROM PERSONAS
	GROUP BY
	NumIdPersona,
	Categoria) AS CATEGORIA_A
LEFT JOIN
	(SELECT
	distinct NumIdPersona,
	Producto,
	COUNT(Producto) AS CantidadTrasaciones,
	SUM(NumTransacciones) AS CantidadTotalTransacciones
	FROM CONSUMO
	WHERE Producto IS NOT NULL
	GROUP BY
	Producto,
	NumIdPersona) AS UNIDADES 
ON CATEGORIA_A.NumIdPersona = UNIDADES.NumIdPersona
WHERE Producto IS NOT NULL
GROUP BY 
	UNIDADES.Producto,
	CATEGORIA_A.Categoria
ORDER BY
	CATEGORIA_A.Categoria ASC,
	CantidadTransacciones DESC;


--No afiliados con mayor frecuencia y mayor valor neto
SELECT TOP(10) *
FROM (
    SELECT 
        PERSONAS.NumIdPersona,
        CASE WHEN PERSONAS.NumIdPersona IS NULL THEN 'No Afiliado' ELSE 'Afiliado' END AS Afiliacion,
        CONSUMO.NumTransacciones,
        CONSUMO.Valor	
    FROM 
        CONSUMO 
        LEFT JOIN PERSONAS ON CONSUMO.NumIdPersona = PERSONAS.NumIdPersona
    WHERE PERSONAS.NumIdPersona IS NULL
    GROUP BY 
        PERSONAS.NumIdPersona,
        CONSUMO.NumTransacciones,
        CONSUMO.Valor
) AS NoAfiliados
ORDER BY
    NumTransacciones DESC,
    Valor DESC;


--Afiliados con mayor frecuencia y mayor valor neto
SELECT TOP(10) *
FROM (
    SELECT 
        PERSONAS.NumIdPersona,
        CASE WHEN PERSONAS.NumIdPersona IS NULL THEN 'No Afiliado' ELSE 'Afiliado' END AS Afiliacion,
        CONSUMO.NumTransacciones,
        CONSUMO.Valor	
    FROM 
        CONSUMO 
        LEFT JOIN PERSONAS ON CONSUMO.NumIdPersona = PERSONAS.NumIdPersona
    WHERE PERSONAS.NumIdPersona IS NOT NULL
    GROUP BY 
        PERSONAS.NumIdPersona,
        CONSUMO.NumTransacciones,
        CONSUMO.Valor
) AS Afiliados
ORDER BY
    NumTransacciones DESC,
    Valor DESC;


--Historico de penetracion en poblacion
SELECT 
	afiliacion, 
	AFILIACION.Periodo,
	COUNT(Afiliacion) AS TotalAfiliacion,
	100.0 * COUNT(Afiliacion) / SUM(COUNT(Afiliacion)) OVER () AS PorcentajeAfiliacion
FROM(SELECT 
		CONSUMO.NumTransacciones, 
		CONSUMO.Periodo, 
		PERSONAS.NumIdPersona,
	CASE WHEN PERSONAS.NumIdPersona IS NULL THEN 'No Afiliado' ELSE 'Afiliado' END AS Afiliacion
	FROM CONSUMO 
	LEFT JOIN PERSONAS 
	ON CONSUMO.NumIdPersona = PERSONAS.NumIdPersona) AS AFILIACION
GROUP BY 
	Afiliacion,
	AFILIACION.Periodo
ORDER BY
	Periodo ASC,
	PorcentajeAfiliacion DESC;


--Productos consumidos en cada segmento
SELECT 
    DISTINCT(SEGMENTO.SegmentoPoblacional),
    PRODUCTO.Producto,
    SUM(PRODUCTO.NumTransacciones) AS CantidadProductos
FROM
    (SELECT 
        DISTINCT NumIdPersona,
        SegmentoPoblacional
     FROM PERSONAS) AS SEGMENTO
LEFT JOIN 
    (SELECT 
        NumIdPersona,
        Producto,
        SUM(NumTransacciones) AS NumTransacciones
     FROM CONSUMO
     GROUP BY NumIdPersona, Producto) AS PRODUCTO
ON SEGMENTO.NumIdPersona = PRODUCTO.NumIdPersona
WHERE PRODUCTO.Producto IS NOT NULL
GROUP BY
    SEGMENTO.SegmentoPoblacional,
    PRODUCTO.Producto
ORDER BY
    SEGMENTO.SegmentoPoblacional DESC,
    CantidadProductos DESC;


--Mejores empresas por consumo individual
SELECT TOP 10
    EMPRESA.id_empresa,
    EMPRESA.SectorCIIU,
    SUM(CONSUMO.NumTransacciones) AS CantidadTransacciones
FROM
    (SELECT 
        id_empresa,
        SectorCIIU
     FROM EMPRESA) AS EMPRESA
LEFT JOIN
    (SELECT  
        NumIdPersona,
        NumTransacciones
     FROM CONSUMO
     WHERE NumTransacciones IS NOT NULL) AS CONSUMO
ON EMPRESA.id_empresa = CONSUMO.NumIdPersona
GROUP BY
    EMPRESA.id_empresa,
    EMPRESA.SectorCIIU
ORDER BY
    CantidadTransacciones DESC;
