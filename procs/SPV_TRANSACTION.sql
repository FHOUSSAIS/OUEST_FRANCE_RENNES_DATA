SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_TRANSACTION
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Gestion de la fermeture des transactions actives
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 22/04/2008
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_TRANSACTION]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	WHILE @@TRANCOUNT > 0
		ROLLBACK TRAN

