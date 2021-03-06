SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestionnaire de Demande du Stock de Masse
--				Traitement Evènement Déclenchement Horloge
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_EVT_HORLOGE]
	@v_abonneInterne   int,
	@v_abonneExterne   int,
	@v_intervalle      int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int		

declare @retour      int,
		@procStock   varchar(128),
		@chaineTrace varchar(7500),
		@local       int

set @CODE_OK = 0
set @CODE_KO = 1

set @retour = @CODE_OK
set @procStock = 'SPC_DDG_EVT_HORLOGE'

	/*SET @ChaineTrace = '@v_abonneInterne : '+CONVERT(varchar,ISNULL(@v_abonneInterne,-1))	
					+' , @v_abonneExterne : '+CONVERT(varchar,ISNULL(@v_abonneExterne,-1))
					+' , @v_intervalle : '+CONVERT(varchar,ISNULL(@v_intervalle,-1))
	EXEC INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace
	*/
if( @v_abonneInterne = -11 )
BEGIN
	-- =============================================
	-- Appel de la proc stock de gestion des demandes
	-- =============================================
	EXEC SPC_DDG_GESTION

END


END

