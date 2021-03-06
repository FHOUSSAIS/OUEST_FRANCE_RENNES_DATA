SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_PURGEEVTENERGIE
-- Paramètre d'entrée	:
-- Paramètre de sortie	:
-- Descriptif		: Cette procedure est appelée pour detruire tous les évenements
--			  energie terminés
-----------------------------------------------------------------------------------------
-- Révisions										
-----------------------------------------------------------------------------------------
-- Date			: 05/10/2004
-- Auteur		: B. Gautier
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 16/03/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Gestion de l'intervalle minimum entre deux changements de batterie
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_PURGEEVTENERGIE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- declaration des constantes
declare @V_ETAT_TERMINE as tinyint

-- définition des constantes d'etat
set @V_ETAT_TERMINE = 3

-- suppression des evenements en cours
delete from EVT_ENERGIE_EN_COURS where EEC_ETAT = @V_ETAT_TERMINE


if @@ERROR <> 0
  return(@@ERROR)
else
  return(0)





