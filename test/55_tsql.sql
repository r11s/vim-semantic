-- ------------------------------------------------------------------
-- Formen-Rechner - Testdatei fuer den Theme-Vergleich (gvim / VS Code)
-- Eigener Code, frei verwendbar (CC0). Stand: 2026-11-26
-- Microsoft SQL Server (T-SQL).  Starten: sqlcmd -i 55_tsql.sql
-- T-SQL kennt keine Klassen: Formen stehen in einer Tabellenvariablen.
-- ------------------------------------------------------------------
SET NOCOUNT ON;
GO

/* Hilfsfunktionen im Schema formen */
IF SCHEMA_ID(N'formen') IS NULL EXEC (N'CREATE SCHEMA formen');
GO

CREATE OR ALTER FUNCTION formen.fmt(@x float, @n int) RETURNS varchar(30)
AS
BEGIN
    RETURN LTRIM(STR(@x, 20, @n));
END;
GO

-- Quadratwurzel nach Newton
CREATE OR ALTER FUNCTION formen.wurzel(@v float) RETURNS float
AS
BEGIN
    DECLARE @eps float = 1e-9, @max_schritte int = 50;
    DECLARE @x float = @v, @nx float, @i int = 1;
    IF @v <= 0 RETURN 0;
    WHILE @i <= @max_schritte
    BEGIN
        SET @nx = 0.5 * (@x + @v / @x);
        IF ABS(@nx - @x) < @eps RETURN @nx;
        SET @x = @nx;
        SET @i += 1;
    END;
    RETURN @x;
END;
GO

CREATE OR ALTER FUNCTION formen.ggt(@a int, @b int) RETURNS int
AS
BEGIN
    DECLARE @r int;
    WHILE @b <> 0
    BEGIN
        SET @r = @a % @b;
        SET @a = @b;
        SET @b = @r;
    END;
    RETURN @a;
END;
GO

CREATE OR ALTER FUNCTION formen.ist_prim(@n int) RETURNS bit
AS
BEGIN
    DECLARE @t int = 2;
    IF @n < 2 RETURN 0;
    WHILE @t * @t <= @n
    BEGIN
        IF @n % @t = 0 RETURN 0;
        SET @t += 1;
    END;
    RETURN 1;
END;
GO

-- Prueft eine Form; wirft bei ungueltigen Massen einen Fehler (THROW 50001)
CREATE OR ALTER PROCEDURE formen.pruefe @art varchar(8), @a float, @b float, @c float
AS
BEGIN
    DECLARE @ok bit = 1, @meldung nvarchar(200);
    IF @art = 'Kreis' SET @ok = IIF(@a > 0, 1, 0);
    ELSE IF @art = 'Rechteck' SET @ok = IIF(@a > 0 AND @b > 0, 1, 0);
    ELSE IF @art = 'Dreieck' SET @ok = IIF(@a + @b > @c AND @a + @c > @b AND @b + @c > @a, 1, 0);
    IF @ok = 0
    BEGIN
        SET @meldung = @art + ' ' + formen.fmt(@a, 1) + '/' + formen.fmt(@b, 1) + '/' + formen.fmt(@c, 1) + ' ungueltig';
        THROW 50001, @meldung, 1;
    END;
END;
GO

DECLARE @alle TABLE (id int IDENTITY(1, 1), art varchar(8), a float, b float, c float);
DECLARE @formen TABLE (art varchar(8), flaeche float, umfang float, ecken int);
DECLARE @id int = 1, @art varchar(8), @a float, @b float, @c float, @s float, @liste varchar(200) = '';

PRINT 'Formen-Rechner';
INSERT INTO @alle (art, a, b, c) VALUES
    ('Kreis', 2.5, NULL, NULL),
    ('Rechteck', 4.0, 3.0, NULL),
    ('Dreieck', 3.0, 4.0, 5.0),
    ('Dreieck', 1.0, 2.0, 10.0);   -- TODO: weitere Formen

WHILE @id <= (SELECT COUNT(*) FROM @alle)
BEGIN
    SELECT @art = art, @a = a, @b = ISNULL(b, 0), @c = ISNULL(c, 0) FROM @alle WHERE id = @id;
    BEGIN TRY
        EXEC formen.pruefe @art, @a, @b, @c;
        SET @s = (@a + @b + @c) / 2;
        INSERT INTO @formen
        SELECT @art,
               CASE @art WHEN 'Kreis' THEN PI() * @a * @a
                         WHEN 'Rechteck' THEN @a * @b
                         ELSE formen.wurzel(@s * (@s - @a) * (@s - @b) * (@s - @c)) END,
               CASE @art WHEN 'Kreis' THEN 2 * PI() * @a
                         WHEN 'Rechteck' THEN 2 * (@a + @b)
                         ELSE @a + @b + @c END,
               CASE @art WHEN 'Kreis' THEN 0 WHEN 'Rechteck' THEN 4 WHEN 'Dreieck' THEN 3 ELSE -1 END;
    END TRY
    BEGIN CATCH
        PRINT 'Fehler: ' + ERROR_MESSAGE();
    END CATCH;
    SET @id += 1;
END;

DECLARE kurs CURSOR LOCAL FAST_FORWARD FOR SELECT art, flaeche, umfang, ecken FROM @formen ORDER BY flaeche;
DECLARE @f float, @u float, @e int;
OPEN kurs;
FETCH NEXT FROM kurs INTO @art, @f, @u, @e;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @art + ': Flaeche=' + formen.fmt(@f, 2) + ' Umfang=' + formen.fmt(@u, 2) + ' ' +
          IIF(@f >= 10.0, 'gross', 'klein') + ' Ecken=' + CAST(@e AS varchar(5));
    FETCH NEXT FROM kurs INTO @art, @f, @u, @e;
END;
CLOSE kurs;
DEALLOCATE kurs;

PRINT 'ggT(48, 18) = ' + CAST(formen.ggt(48, 18) AS varchar(10));
SET @id = 2;
WHILE @id <= 30
BEGIN
    IF formen.ist_prim(@id) = 1 SET @liste += ' ' + CAST(@id AS varchar(3));
    SET @id += 1;
END;
PRINT 'Primzahlen bis 30:' + @liste;
PRINT 'Wurzel(2) = ' + formen.fmt(formen.wurzel(2), 8);
PRINT 'Maske: ' + CAST(CAST(0xFF AS int) & CAST(0xAA AS int) AS varchar(10));   -- kein Binaerliteral in T-SQL
PRINT 'Skala: ' + CAST(1000000 / 8 AS varchar(10));
GO
