SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: LIB_CONNECTION
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion de l'unicité d'accès
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[LIB_CONNECTION]
	@v_program_name nvarchar(128),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	SET @v_retour = 113
	SET @v_program_name = RTRIM(LTRIM(@v_program_name)) + '%'
	IF EXISTS (SELECT COUNT(*) FROM master.dbo.sysprocesses (NOLOCK)
		WHERE program_name like @v_program_name AND DB_NAME(dbid) = DB_NAME() HAVING COUNT(*) > 1)
		SET @v_retour = 935
	ELSE
		SET @v_retour = 0



