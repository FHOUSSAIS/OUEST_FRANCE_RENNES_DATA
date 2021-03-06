SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestionnaire de Demande du Stock de Masse
--				Traitement Evènement Déclenchement Horloge
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_EVT_HORLOGE]
	@v_abonneInterne   int,
	@v_abonneExterne   int,
	@v_intervalle      int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int		

declare @retour      int,
		@Trace varchar(7500)

set @CODE_OK = 0
set @CODE_KO = 1

set @retour = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Démaculeuse'

if( @v_abonneInterne = -8 ) 
BEGIN
	-- =============================================
	-- Appel de la proc stock de gestion des demandes
	-- =============================================
	EXEC SPC_DDD_GESTION

END


END

