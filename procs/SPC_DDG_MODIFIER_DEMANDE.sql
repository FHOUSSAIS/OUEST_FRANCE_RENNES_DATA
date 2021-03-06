SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modifier les Demandes de réorga du Stock de Masse
-- @v_idDemande	: Id de demande 
-- @v_etat		: Etat de la demande
-- @v_priorite	: Priorité
-- @v_nbRestant	: Nombre de palettes restantes
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_MODIFIER_DEMANDE]
	@v_idDemande	varchar(20),
	@v_etat			int = NULL,
	@v_priorite		int = NULL,
	@v_nbRestant	int = NULL
AS
BEGIN

declare @CODE_OK int = 0
declare	@CODE_KO int = 1

declare @ETAT_DMD_NOUVELLE		int = 0
declare @ETAT_DMD_EN_ATTENTE	int = 1
declare @ETAT_DMD_EN_COURS		int = 2
declare @ETAT_DMD_TERMINEE		int = 3
declare @ETAT_DMD_SUSPENDUE		int = 11
declare @ETAT_DMD_ANNULEE		int = 12

declare @retour int = @CODE_OK
declare @procStock varchar(128) = OBJECT_NAME(@@PROCID)
declare @moniteur varchar(128) = 'Gestionnaire Demande Reorganisation'
declare @trace varchar(7500)

SET @trace = 'Modification de la demande ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @v_etat), 'NULL')
+ ', @v_priorite = ' + ISNULL(CONVERT(VARCHAR, @v_priorite), 'NULL')
+ ', @v_nbRestant = ' + ISNULL(CONVERT(VARCHAR, @v_nbRestant), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

	DECLARE @libelleEtat VARCHAR(8000) = (SELECT dbo.INT_GETLIBELLE(dbo.SPC_DMD_ETAT.SDE_IDTRADUCTION, 'fra') FROM dbo.SPC_DMD_ETAT WHERE dbo.SPC_DMD_ETAT.SDE_IDETAT = @v_etat)
	
	-- Vérifcation Existance Demande
	IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_REORGA_STOCK_GENERAL WHERE dbo.SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDDEMANDE = @v_idDemande)
	BEGIN
		SET @trace = 'Modifier Demande, la demande n existe pas : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
		SET @retour = @CODE_KO
	END
	
	IF (@retour = @CODE_OK) 
	BEGIN
		UPDATE SPC_DMD_REORGA_STOCK_GENERAL
			SET	SDG_ETAT = ISNULL(@v_etat, SDG_ETAT),
			SDG_PRIORITE = ISNULL(@v_priorite, SDG_PRIORITE),
			SDG_NBRESTANT = ISNULL(@v_nbRestant, SDG_NBRESTANT)
		WHERE SDG_IDDEMANDE = @v_idDemande
	END

	-- tester le code erreur est inutile car pas de try/catch
	SET @retour = @@ERROR

	if( @retour = @CODE_OK )
	begin
		SET @trace = 'la demande a été mise à jour ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
			+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')	
			+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @v_etat), 'NULL')
			+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
		EXEC SPC_DDG_INSERER_TRACE @v_idDemande = @v_idDemande
	end

	if( @retour <> @CODE_OK )
	begin
		SET @trace = 'Erreur a la mise a jour de la demande ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
				+ ', @v_idDemande = ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')	
				+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @v_etat), 'NULL')
				+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	end

RETURN @retour
END
