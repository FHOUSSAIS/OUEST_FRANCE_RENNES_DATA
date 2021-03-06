SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON






-----------------------------------------------------------------------------------------
-- Procédure		: SPV_READECHANGE
-- Paramètre d'entrée	: @v_interface : Identifiant interface
-- Paramètre de sortie	: 
-- Descriptif		: Lecture des échanges de données entre bases de données
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_READECHANGE]
	@v_interface int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	SELECT ECH_TABLE FROM ECHANGE WHERE ECH_INTERFACE = @v_interface AND ECH_READ = 1

