SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETCRITERECALCULEZONE
-- Paramètre d'entrée	: @v_cri_idcritere : Identifiant critère
--			  @v_iag_idagv : Identifiant AGV
--			  @v_cri_parametre : Paramètres
-- Paramètres de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_INCONNU : Critère de mission inconnu
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Evaluation des critères de zones calculés
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETCRITERECALCULEZONE]
	@v_cri_idcritere int,
	@v_iag_idagv tinyint,
	@v_cri_parametre varchar(3500)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_zon_idzone int,
	@v_zne_capaciteminimale tinyint,
	@v_zne_capacitemaximale tinyint,
	@v_zne_surreservation bit,
	@v_crz_valeur varchar(8000)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK int,
	@CODE_KO int

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@DESC_ENVOYE tinyint,
	@ETAT_SOUS_CAPACITE tinyint,
	@ETAT_NORMAL tinyint,
	@ETAT_PLEIN tinyint,
	@ETAT_SUR_CAPACITE tinyint

-- Déclaration des constantes de critères
DECLARE
	@CRIT_ETATZONE tinyint,
	@CRIT_NOMBREAGVSDESTINATIONZONE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @ETAT_ENATTENTE = 1
	SET @DESC_ENVOYE = 13
	SET @ETAT_SOUS_CAPACITE = 0
	SET @ETAT_NORMAL = 1
	SET @ETAT_PLEIN = 2
	SET @ETAT_SUR_CAPACITE = 3
	SET @CRIT_ETATZONE = 152
	SET @CRIT_NOMBREAGVSDESTINATIONZONE = 154

-- Initialisation de la variable de retour
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	IF @v_cri_idcritere IN (@CRIT_ETATZONE, @CRIT_NOMBREAGVSDESTINATIONZONE)
	BEGIN
		DECLARE c_zone CURSOR LOCAL FAST_FORWARD FOR SELECT ZNE_ID, ZNE_CAP_MIN, ZNE_CAP_MAX, ZNE_BOOKING FROM ZONE
		OPEN c_zone
		FETCH NEXT FROM c_zone INTO @v_zon_idzone, @v_zne_capaciteminimale, @v_zne_capacitemaximale, @v_zne_surreservation
		IF @@FETCH_STATUS = 0
		BEGIN
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_zon_idzone)
					AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE))
					OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE, (SELECT CZO_ADR_KEY_SYS, CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_zon_idzone) ZONE_CONTENU
					WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE
					AND TAC_IDADRSYS = CZO_ADR_KEY_SYS AND TAC_IDADRBASE = CZO_ADR_KEY_BASE))
				IF @v_cri_idcritere = @CRIT_ETATZONE
					SET @v_crz_valeur = CASE WHEN @v_crz_valeur < @v_zne_capaciteminimale THEN @ETAT_SOUS_CAPACITE
						WHEN @v_crz_valeur >= @v_zne_capaciteminimale AND @v_crz_valeur < @v_zne_capacitemaximale THEN @ETAT_NORMAL
						WHEN @v_crz_valeur = @v_zne_capacitemaximale THEN @ETAT_PLEIN
						WHEN @v_crz_valeur > @v_zne_capacitemaximale THEN CASE @v_zne_surreservation WHEN 1 THEN @ETAT_PLEIN ELSE @ETAT_SUR_CAPACITE END END
				EXEC @v_status = INT_SETCRITEREZONE @v_cri_idcritere, @v_zon_idzone, @v_crz_valeur
				SET @v_error = @@ERROR
				IF NOT (@v_status = @CODE_OK AND @v_error = 0)
				BEGIN
					SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
					BREAK
				END
				FETCH NEXT FROM c_zone INTO @v_zon_idzone, @v_zne_capaciteminimale, @v_zne_capacitemaximale, @v_zne_surreservation
			END
			IF @v_status = @CODE_OK AND @v_error = 0
				SET @v_retour = @CODE_OK
		END
		ELSE
			SET @v_retour = @CODE_OK
		CLOSE c_zone
		DEALLOCATE c_zone
	END
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour




