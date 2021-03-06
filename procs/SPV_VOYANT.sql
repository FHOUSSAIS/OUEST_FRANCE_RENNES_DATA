SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_VOYANT
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Mise à jour des voyants Logistic Core et Traffic Control
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_VOYANT]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	IF NOT EXISTS (SELECT COUNT(*) FROM master.dbo.sysprocesses (NOLOCK)
		WHERE program_name like 'Logistic Core%' AND DB_NAME(dbid) = DB_NAME() HAVING COUNT(*) > 0)
		UPDATE PARAMETRE SET PAR_VAL = 0 WHERE PAR_NOM = 'RUNNING'
	IF NOT EXISTS (SELECT COUNT(*) FROM master.dbo.sysprocesses (NOLOCK)
		WHERE program_name like 'Traffic Control%' AND DB_NAME(dbid) = DB_NAME() HAVING COUNT(*) > 0)
		UPDATE INTERFACE_PILOTAGE_UDP SET IPI_ETAT = 0

