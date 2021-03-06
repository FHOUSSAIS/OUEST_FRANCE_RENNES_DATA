SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Génération d'un nuémro de demande + Préfixe
-- @v_idCompteur int : Compteur de la demande
-- @v_idDemande varchar(20) : Identifiant de demande généré
-- =============================================
CREATE PROCEDURE SPC_DMD_CREER_ID 
	@v_idCompteur int,
	@v_idDemande varchar(20) out
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @valeurCompteur int
DECLARE @libelleCompteur varchar(8000)

SET @trace = 'Génération Identifiant demande : ' + ISNULL(CONVERT(VARCHAR, @v_idCompteur), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

-- Récupération de la valeur du compteur et du préfixe de la demande
SELECT
	@valeurCompteur = dbo.SPC_DMD_COMPTEUR.SDC_COMPTEUR + 1,
	@v_idDemande = dbo.SPC_DMD_COMPTEUR.SDC_PREFIXE,
	@libelleCompteur = dbo.INT_GETLIBELLE(dbo.SPC_DMD_COMPTEUR.SDC_TRADUCTION, 'fra')
FROM dbo.SPC_DMD_COMPTEUR
WHERE dbo.SPC_DMD_COMPTEUR.SDC_IDCOMPTEUR = @v_idCompteur

-- Reconstitution de l'identifiant de demande
SET @v_idDemande = @v_idDemande + '_' + CONVERT(VARCHAR, @valeurCompteur)

SET @trace = 'Identifiant demande : ' + ISNULL(CONVERT(VARCHAR, @v_idCompteur), 'NULL')
		+ ', @valeurCompteur : ' + ISNULL(CONVERT(VARCHAR, @valeurCompteur), 'NULL')
		+ ', @v_idDemande : ' + ISNULL(CONVERT(VARCHAR, @v_idDemande), 'NULL')
		+ ', @libelleCompteur : ' + ISNULL(CONVERT(VARCHAR, @libelleCompteur), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

-- Mise à jour de la valeur du compteur
UPDATE dbo.SPC_DMD_COMPTEUR
SET SDC_COMPTEUR = @valeurCompteur
WHERE dbo.SPC_DMD_COMPTEUR.SDC_IDCOMPTEUR = @v_idCompteur

SET @trace = 'MAJ Compteur : ' + ISNULL(CONVERT(VARCHAR, @v_idCompteur), 'NULL')
		+ ', @valeurCompteur : ' + ISNULL(CONVERT(VARCHAR, @valeurCompteur), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

RETURN @retour

END

