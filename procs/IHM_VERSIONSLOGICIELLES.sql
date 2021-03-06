SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON





-----------------------------------------------------------------------------------------
-- Procédure		: IHM_VERSIONSLOGICIELLES
-- Paramètre d'entrées	: 
-- Paramètre de sorties	: 
-- Descriptif		: Visualisation des versions logicielles
--                        Supprime les enregistrements des OperatingScreens qui ne tournent plus
--                        Laisse en visu tous les autres logiciels  (eteints ou allumes)
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 31/07/2014
-- Auteur		: Guillaume DELLOYE
-- Libellé		: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_VERSIONSLOGICIELLES]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Proc stock de nettoyage et visualisation
DELETE VERSIONS_LOGICIELLES WHERE VLO_NOM_PROCESS like 'Operating Screens%'
AND NOT EXISTS (SELECT 1 FROM master.dbo.sysprocesses WHERE program_name = 'Operating Screens - Principal' AND hostname = VLO_NOM_MACHINE COLLATE database_default)

SELECT * FROM VERSIONS_LOGICIELLES

