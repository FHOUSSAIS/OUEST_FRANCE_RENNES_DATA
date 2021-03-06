SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/* =============================================
-- Description:	Simulation - Création d'une charge de type Bobine
		@v_idCharge INT OUTPUT = Retour de l'identifiant,
		@v_chg_poids INT = Poids (Null par Défaut),
		@v_chg_laize INT = Laize (Null par Défaut),
		@v_chg_diametre INT = Diamètre (Null par Défaut),
		@v_chg_sensEnroulement INT = Sens Enroulement (Null par Défaut),
		@v_chg_grammage NUMERIC(4,2) = Grammage (Null par Défaut),
		@v_chg_idFournisseur INT = Fournisseur (Null par Défaut),
		@v_idSysteme BIGINT
		@v_idBase BIGINT		= Adresse de l'adresse de la création (Obligatoire)
		@v_idSousBase BIGINT
Si Propriétées Nulles alors on va chercher au hasard dans les tables
Adresse obligatoire, si une charge existe sur cette adresse, elle sera renvoyée (donc pas de création de charge)
-- ============================================*/
CREATE PROCEDURE [dbo].[SPC_SIMU_CREERBOBINE] 
	@v_idCharge INT OUTPUT,
	@v_chg_poids INT = NULL,
	@v_chg_laize INT = NULL,
	@v_chg_diametre INT = NULL,
	@v_chg_sensEnroulement INT = NULL,
	@v_chg_grammage NUMERIC(5,2) = NULL,
	@v_chg_idFournisseur INT = NULL,
	@v_idSysteme BIGINT,
	@v_idBase BIGINT,
	@v_idSousBase BIGINT
AS
BEGIN
DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1	

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Simulation'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

SET @trace = 'Création d une bobine'
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

-- Vérification Adresse
SELECT
	@v_idCharge = dbo.INT_CHARGE_VIVANTE.CHG_IDCHARGE
FROM dbo.INT_CHARGE_VIVANTE
INNER JOIN INT_ADRESSE
	ON ADR_IDSYSTEME = CHG_IDSYSTEME
	AND ADR_IDBASE = CHG_IDBASE
	AND ADR_IDSOUSBASE = CHG_IDSOUSBASE
WHERE dbo.INT_CHARGE_VIVANTE.CHG_IDSYSTEME = @v_idSysteme
AND dbo.INT_CHARGE_VIVANTE.CHG_IDBASE = @v_idBase
AND dbo.INT_CHARGE_VIVANTE.CHG_IDSOUSBASE = @v_idSousBase
AND dbo.INT_ADRESSE.ADR_IDTYPEMAGASIN <> 3

IF(@v_idCharge IS NULL)
BEGIN
	SET @trace = 'Pas de charge trouvée => Création'
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
	-- Création Charge
	SET @v_chg_poids = 950.00
	SET @v_chg_laize = ISNULL(@v_chg_laize, (SELECT TOP 1 dbo.SPC_CHG_LAIZE.SCL_LAIZE FROM dbo.SPC_CHG_LAIZE ORDER BY NEWID()))
	SET @v_chg_diametre = ISNULL(@v_chg_diametre, (SELECT TOP 1 dbo.SPC_CHG_DIAMETRE.SCD_DIAMETRE FROM dbo.SPC_CHG_DIAMETRE ORDER BY NEWID()))
	SET @v_chg_sensEnroulement = ISNULL(@v_chg_sensEnroulement, (SELECT TOP 1 dbo.SPC_CHG_SENSENROULEMENT.SSE_SENSENROULEMENT FROM dbo.SPC_CHG_SENSENROULEMENT ORDER BY NEWID()))
	SET @v_chg_grammage = ISNULL(@v_chg_grammage, (SELECT TOP 1 dbo.SPC_CHG_GRAMMAGE.SCG_GRAMMAGE FROM dbo.SPC_CHG_GRAMMAGE ORDER BY NEWID()))
	SET @v_chg_idFournisseur = ISNULL(@v_chg_idFournisseur, (SELECT TOP 1 dbo.SPC_CHG_FOURNISSEUR.SCF_IDFOURNISSEUR from dbo.SPC_CHG_FOURNISSEUR ORDER BY NEWID()))

	EXEC @retour = dbo.SPC_CHG_CREER_BOBINE 	@v_idcharge = @v_idCharge out,
		@v_poids = @v_chg_poids,
		@v_laize = @v_chg_laize,
		@v_diametre = @v_chg_diametre,
		@v_sensenroulement = @v_chg_sensEnroulement,
		@v_grammage  = @v_chg_grammage,
		@v_fournisseur = @v_chg_idFournisseur,
		@v_idsysteme = @v_idSysteme,
		@v_idbase = @v_idBase,
		@v_idsousbase = @v_idSousBase,
		@v_CodeABarre = 'CABA16CARACTERES'
	IF(@retour <> @CODE_OK)
	BEGIN
		SET @trace = 'SPC_CHG_CREER_BOBINE' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'DEBUG',
									@v_trace = @trace
	END
END
ELSE
BEGIN
	SET @trace = 'Charge trouvée => Renvoi'
	SET @trace = @procStock + '/' + @trace
	EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
								@v_log_idlog = 'DEBUG',
								@v_trace = @trace
END
END

