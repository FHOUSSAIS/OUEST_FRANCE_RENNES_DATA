SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SELECTORDRE
-- Paramètre d'entrée	: @v_ord_idordre : Identifiant de l'ordre
--			  @v_type : Type
--			    0 : Mouvement
--			    1 : Action
-- Paramètre de sortie	:
-- Descriptif		: Sélection de l'ordre à émettre
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SELECTORDRE]
	@v_ord_idordre int,
	@v_type bit
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
	@v_mis_idmission int,
	@v_chg_idcharge int,
	@v_chg_couche tinyint,
	@v_tac_idsystemeexecution bigint,
	@v_tac_idbaseexecution bigint,
	@v_tac_idsousbaseexecution bigint,
	@v_accesbase bit

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_ENVOYE tinyint

-- Déclaration des constantes de types d'actions
DECLARE
	@ACTI_PRIMAIRE bit

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_ENVOYE = 13
	SET @ACTI_PRIMAIRE = 0
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	IF @v_type = 1
	BEGIN
		-- Vérification d'un affinage d'adresse nécessaire
		DECLARE c_tache CURSOR LOCAL FAST_FORWARD FOR SELECT MIS_IDMISSION, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE, TAC_ACCES_BASE
			FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE, ACTION, ADRESSE, BASE, MISSION WHERE TAC_IDORDRE = @v_ord_idordre AND ATA_IDTACHE = TAC_IDTACHE AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
			AND ACT_IDACTION = ATA_IDACTION AND ACT_CHARGE = 1 AND ACT_OCCUPATION = 1 AND ADR_SYSTEME = TAC_IDADRSYS AND ADR_BASE = TAC_IDADRBASE AND ADR_SOUSBASE = TAC_IDADRSSBASE AND ADR_TYPE = 1
			AND BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE AND MIS_IDMISSION = TAC_IDMISSION AND MIS_IDCHARGE IS NULL
			AND BAS_TYPE_MAGASIN IN (@TYPE_STOCK, @TYPE_PREPARATION) AND BAS_ACCUMULATION = 1 AND BAS_EMPLACEMENT = 0
		OPEN c_tache
		FETCH NEXT FROM c_tache INTO @v_mis_idmission, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution, @v_accesbase
		WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
		BEGIN
			SELECT TOP 1 @v_chg_idcharge = CHG_ID, @v_chg_couche = CHG_COUCHE FROM CHARGE
				WHERE CHG_ADR_KEYSYS = @v_tac_idsystemeexecution AND CHG_ADR_KEYBASE = @v_tac_idbaseexecution
				AND CHG_ADR_KEYSSBASE = @v_tac_idsousbaseexecution AND CHG_COUCHE = ISNULL(@v_chg_couche, CHG_COUCHE) AND CHG_TODESTROY = 0
				AND NOT EXISTS (SELECT 1 FROM TACHE, MISSION WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND MIS_IDCHARGE = CHG_ID AND MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE))
				ORDER BY CASE ISNULL(@v_accesbase, 0) WHEN 0 THEN CHG_POSY ELSE -CHG_POSY END, CHG_COUCHE DESC, CHG_POSZ DESC
			IF @v_chg_idcharge IS NOT NULL
			BEGIN
				UPDATE MISSION SET MIS_IDCHARGE = @v_chg_idcharge WHERE MIS_IDMISSION = @v_mis_idmission
				SET @v_error = @@ERROR
				IF @v_error <> 0
					SET @v_status = @CODE_KO_SQL
			END
			FETCH NEXT FROM c_tache INTO @v_mis_idmission, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution, @v_accesbase
		END
		CLOSE c_tache
		DEALLOCATE c_tache
		SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	END
	ELSE
		SET @v_retour = @CODE_OK
	SELECT ORD_IDORDRE, TAC_IDMISSION, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE, ISNULL(TAC_OFSPROFONDEUR, 0) TAC_OFSPROFONDEUR,
		ISNULL(TAC_OFSNIVEAU, 0) TAC_OFSNIVEAU, ISNULL(TAC_OFSCOLONNE, 0) TAC_OFSCOLONNE, 
		CASE WHEN TAG_TYPE_OUTIL IN (1, 2) THEN CASE ACT_CHARGE WHEN 1 THEN ISNULL(EMB_ENGAGEMENT, ISNULL((SELECT PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'OFFSETENGAGEMENT'), 50)) ELSE 0 END ELSE 0 END TAC_OFSENGAGEMENT,
		TAC_ACCES_BASE, CASE WHEN ISNULL(TAC_ACCES_BASE, 0) = 0 THEN ISNULL(STR_LONGUEUR_DEBUT_COURANTE, 0) ELSE ISNULL(STR_LONGUEUR_FIN_COURANTE, 0) END STR_LONGUEUR_DEBUT, ISNULL(STR_ECART_EXPLOITATION, ISNULL(STR_ECART_INDUSTRIEL, 0)) STR_ECART_INTERCHARGE,
		ATA_IDACTION, ATA_IDTYPEACTION, ATA_OPTION_ACTION, ACT_ACTION, CASE ACT_CHARGE WHEN 1 THEN ISNULL(MIS_IDCHARGE, 0) ELSE MIS_IDCHARGE END MIS_IDCHARGE, CHG_POIDS,
		CASE CHG_FACE WHEN 0 THEN CHG_LARGEUR ELSE CHG_LONGUEUR END CHG_LARGEUR,
		CASE CHG_FACE WHEN 0 THEN CHG_LONGUEUR ELSE CHG_LARGEUR END CHG_LONGUEUR,
		CHG_HAUTEUR, CHG_ORIENTATION, CHG_STABILITE
		FROM MISSION LEFT OUTER JOIN CHARGE ON MIS_IDCHARGE = CHG_ID LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE,
		ORDRE_AGV, TACHE LEFT OUTER JOIN STRUCTURE ON STR_SYSTEME = TAC_IDADRSYS AND STR_BASE = TAC_IDADRBASE AND STR_SOUSBASE = TAC_IDADRSSBASE,
		ASSOCIATION_TACHE_ACTION_TACHE, ACTION, INFO_AGV, TYPE_AGV
		WHERE ORD_IDORDRE = @v_ord_idordre AND ((@v_type = 0) OR (@v_type = 1 AND ACT_ACTION = 1))
		AND IAG_ID = ORD_IDAGV AND TAG_ID = IAG_TYPE
		AND TAC_IDORDRE = ORD_IDORDRE AND TAC_IDMISSION = MIS_IDMISSION
		AND MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
		AND TAC_IDTACHE = ATA_IDTACHE AND ACT_IDACTION = ATA_IDACTION
		ORDER BY CASE ACT_OCCUPATION WHEN 1 THEN CASE ISNULL(TAC_ACCES_BASE, 0) WHEN 0 THEN CHG_POSY ELSE -CHG_POSY END ELSE CHG_POSY END, CHG_POSZ, TAC_IDMISSION
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN

