SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modifier les Demandes de Mouvements TRR
-- @v_idDemande	: Id de demande 
-- @v_etat		: Etat de la demande
-- @v_priorite	: Priorité
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMR_MODIFIER_DEMANDE]
	@v_idDemande	VARCHAR(20),
	@v_etat			INT = NULL,
	@v_priorite		INT = NULL
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Mouvement TRR'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @libelleEtat VARCHAR(8000) = (SELECT dbo.INT_GETLIBELLE(dbo.SPC_DMD_ETAT.SDE_IDTRADUCTION, 'fra') FROM dbo.SPC_DMD_ETAT WHERE dbo.SPC_DMD_ETAT.SDE_IDETAT = @v_etat)

SET @trace = 'Modification de la demande ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
		+ ', @v_etat = ' + ISNULL(CONVERT(VARCHAR, @v_etat), 'NULL')
		+ ', @libelleEtat = ' + ISNULL(CONVERT(VARCHAR, @libelleEtat), 'NULL')
		+ ', @v_priorite = ' + ISNULL(CONVERT(VARCHAR, @v_priorite), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

-- Vérification Données d'entrée
-- Vérifcation Existance Demande
IF NOT EXISTS(SELECT 1 FROM dbo.SPC_DMD_MOUVEMENT_TRR WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE = @v_idDemande)
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
	UPDATE dbo.SPC_DMD_MOUVEMENT_TRR
	SET	SDM_ETAT = ISNULL(@v_etat, SDM_ETAT),
		SDM_PRIORITE = ISNULL(@v_priorite, dbo.SPC_DMD_MOUVEMENT_TRR.SDM_PRIORITE)
	WHERE dbo.SPC_DMD_MOUVEMENT_TRR.SDM_IDDEMANDE = @v_idDemande

	-- tester le code erreur est inutile car pas de try/catch
	SET @retour = @@ERROR
END

IF (@retour <> @CODE_OK) 
BEGIN
	SET @trace = 'Erreur a la mise a jour de la demande ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'ERREUR',
								@v_trace = @trace
END
ELSE
BEGIN
	SET @trace = 'la demande a été mise à jour ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
END

-- Trace Historique
EXEC dbo.SPC_DMR_INSERER_TRACE @v_idDemande = @v_idDemande

RETURN @retour
END
