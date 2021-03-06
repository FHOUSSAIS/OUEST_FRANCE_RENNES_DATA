SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_CAPACITEACCUEILAGV
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant de l'AGV
--						  @v_mis_idmission : Identifiant de la mission que l'on souhaite attribuer à l'AGV
-- Paramètre de sortie	: Code de retour par défaut
--						  @CODE_OUI : L'AGV peut accueillir la nouvelle mission et ne sera pas plein
--						  @CODE_NON : L'AGV peut accueillir la nouvelle mission et sera plein
--						  @CODE_KO_INCOMPATIBLE : La mission n'est pas compatible avec les capacités physiques des outils
-- Descriptif		: Cette procédure teste si l'occupation d'un AGV autorise l'attribution de la mission
--			  passée en paramètre et si cette mission est compatible avec les capacités physiques de ses outils
--			  Le calcul tient compte du nombre d'emplacements disponibles par outil,
--			  de tous les ordres (calculés et à venir) susceptibles d'occuper des places
--			  supplémentaires sur l'AGV et des ordres (en cours uniquement) susceptibles de libérer
--			  des places sur l'AGV
--			  Le calcul prend également en compte si l'attribution est liée à une anticipation auquel cas
--			  seules les missions combinables avec l'ordre en cours sont attribuables
--			  En cas d'exception, la procédure renvoie CODE_NON
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_CAPACITEACCUEILAGV]
	@v_iag_idagv tinyint,
	@v_mis_idmission integer,
	@v_anticipation bit,
	@v_debutAction bit
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_retour int,
	@v_emplacement_outil tinyint,
	@v_outil_disponible tinyint,
	@v_base_occupation tinyint,
	@v_nbEmplDispo tinyint,
	@v_nbEmplAOccuper tinyint,
	@v_nbEmplALiberer tinyint,
	@v_ord_idordre int,
	@v_tac_idtache int,
	@v_tag_type_outil tinyint

DECLARE @v_tache table (TAC_IDTACHE int NOT NULL, TAC_IDMISSION int NOT NULL, TAC_SYSTEME bigint NOT NULL, TAC_BASE bigint NOT NULL)
DECLARE @v_ordre table (TAC_IDTACHE int NOT NULL, ORD_IDORDRE int NOT NULL)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_OUI tinyint,
	@CODE_NON tinyint,
	@CODE_KO_INCOMPATIBLE tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_ANNULE tinyint,
	@ETAT_TERMINE tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_EXECUTION tinyint

-- Déclaration des constantes de type d'action
DECLARE
	@ACTION_PRIMAIRE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_OUI = 5
	SET @CODE_NON = 6
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @ACTION_PRIMAIRE = 0
	SET @AFFI_EXECUTION = 2

-- Initialisation de la variable de retour
	SET @v_retour = @CODE_KO

	-- Un AGV peut s'attribuer plusieurs missions simultanément seulement si elles sont du même type
	IF ((NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE))
		OR (EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE)
		AND EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDMISSION = @v_mis_idmission AND MIS_TYPEMISSION = (SELECT DISTINCT MIS_TYPEMISSION FROM ORDRE_AGV,
		TACHE, MISSION WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE AND TAC_IDORDRE = ORD_IDORDRE
		AND MIS_IDMISSION = TAC_IDMISSION))))
	BEGIN
		SELECT TOP 1 @v_ord_idordre = ORD_IDORDRE FROM ORDRE_AGV WHERE ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
			AND ORD_IDAGV = @v_iag_idagv ORDER BY ORD_POSITION
		IF @v_anticipation = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM TACHE INNER JOIN ASSOCIATION_TACHE_ACTION_TACHE ON ATA_IDTACHE = TAC_IDTACHE
				INNER JOIN ACTION ON ACT_IDACTION = ATA_IDACTION
				WHERE TAC_IDORDRE = @v_ord_idordre AND ATA_IDTYPEACTION = @ACTION_PRIMAIRE AND ACT_ACTION = 1)
			BEGIN
				SELECT TOP 1 @v_tac_idtache = TAC_IDTACHE FROM TACHE WHERE TAC_IDMISSION = @v_mis_idmission ORDER BY TAC_POSITION_TACHE
				IF NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDTACHE = @v_tac_idtache AND TAC_AFFINAGEADR = @AFFI_EXECUTION)
					AND NOT EXISTS (SELECT 1 FROM TACHE TACHEMISSION INNER JOIN ASSOCIATION_TACHE_ACTION_TACHE ACTIONTACHE ON ACTIONTACHE.ATA_IDTACHE = TACHEMISSION.TAC_IDTACHE
					WHERE TACHEMISSION.TAC_IDTACHE = @v_tac_idtache
					AND NOT EXISTS (SELECT 1 FROM TACHE TACHEORDRE INNER JOIN ASSOCIATION_TACHE_ACTION_TACHE ACTIONORDRE ON ACTIONORDRE.ATA_IDTACHE = TACHEORDRE.TAC_IDTACHE
					WHERE TACHEORDRE.TAC_IDORDRE = @v_ord_idordre AND TACHEORDRE.TAC_IDADRSYS = TACHEMISSION.TAC_IDADRSYS AND TACHEORDRE.TAC_IDADRBASE = TACHEMISSION.TAC_IDADRBASE
					AND ACTIONTACHE.ATA_IDACTION = ACTIONORDRE.ATA_IDACTION AND ACTIONTACHE.ATA_IDTYPEACTION = ACTIONORDRE.ATA_IDTYPEACTION
					AND ISNULL(ACTIONTACHE.ATA_OPTION_ACTION, 0) = ISNULL(ACTIONORDRE.ATA_OPTION_ACTION, 0)
					AND TACHEMISSION.TAC_NBACTION = TACHEORDRE.TAC_NBACTION))
					SET @v_retour = @CODE_OK
			END
			ELSE
				SET @v_retour = @CODE_OK	
		END
		ELSE
			SET @v_retour = @CODE_OK
		IF @v_retour = @CODE_OK
		BEGIN
			-- Test de la capacité d'accueil de la nouvelle mission
			-- Vérification si ses actions sont susceptibles d'occuper une place supplémentaire sur l'AGV
			IF EXISTS (SELECT 1 FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE TAC_IDMISSION = @v_mis_idmission AND ATA_IDTACHE = TAC_IDTACHE
				AND ACT_IDACTION = ATA_IDACTION AND ACT_OCCUPATION = 1)
			BEGIN
				-- Test de la disponibilité des outils de l'AGV
				-- Hypothèse :
				--	les emplacements d'un même outil ne sont pas indépendants
				--	les outils de l'AGV possèdent tous le même nombre d'emplacements
				-- Calcul du nombre d'emplacements par outil
				SELECT @v_emplacement_outil = MIN(EMPLACEMENT) FROM (SELECT COUNT(*) EMPLACEMENT FROM ADRESSE INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
					WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_iag_idagv GROUP BY ADR_COLONNE) OUTIL
				-- Calcul du nombre d'outils disponibles
				--  Un outil est considéré disponible s'il est vide ou sera vide après l'exécution des ordres en cours libérant l'outil
				SELECT @v_outil_disponible = COUNT(*) FROM OUTIL_AGV WHERE OUA_IDAGV = @v_iag_idagv
					AND @v_emplacement_outil = (SELECT COUNT(*) FROM ADRESSE INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
					WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = OUA_IDAGV AND ADR_COLONNE = OUA_COLONNE
					AND (NOT EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = ADR_SYSTEME AND CHG_ADR_KEYBASE = ADR_BASE AND CHG_ADR_KEYSSBASE = ADR_SOUSBASE)
					OR EXISTS (SELECT 1 FROM CHARGE INNER JOIN MISSION ON MIS_IDCHARGE = CHG_ID INNER JOIN TACHE ON TAC_IDMISSION = MIS_IDMISSION INNER JOIN ORDRE_AGV ON ORD_IDORDRE = TAC_IDORDRE
					WHERE CHG_ADR_KEYSYS = ADR_SYSTEME AND CHG_ADR_KEYBASE = ADR_BASE AND CHG_ADR_KEYSSBASE = ADR_SOUSBASE AND ORD_IDETAT = @ETAT_ENCOURS
					AND EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE ATA_IDTACHE = TAC_IDTACHE
					AND ATA_IDTYPEACTION = @ACTION_PRIMAIRE AND ACT_IDACTION = ATA_IDACTION AND ACT_OCCUPATION = -1))))
				--	Sélection des tâches des ordres existants ainsi que celles de la mission à attribuer occupant l'outil
				INSERT INTO @v_tache SELECT TAC_IDTACHE, TAC_IDMISSION, ISNULL(TAC_IDAFFINAGEADRSYS, TAC_IDADRSYS), ISNULL(TAC_IDAFFINAGEADRBASE, TAC_IDADRBASE) FROM TACHE LEFT OUTER JOIN ORDRE_AGV ON ORD_IDORDRE = TAC_IDORDRE
					WHERE ((TAC_IDMISSION = @v_mis_idmission) OR (ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE) AND (@v_debutAction = 0 OR (@v_debutAction = 1 AND ORD_IDORDRE <> @v_ord_idordre))))
					AND EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE ATA_IDTACHE = TAC_IDTACHE
					AND ATA_IDTYPEACTION = @ACTION_PRIMAIRE AND ACT_IDACTION = ATA_IDACTION AND ACT_OCCUPATION = 1)
				--	Sélection des ordres existants en cours occupant l'outil
				IF @v_debutAction = 1
					INSERT INTO @v_ordre SELECT TAC_IDTACHE, ORD_IDORDRE FROM ORDRE_AGV INNER JOIN TACHE ON TAC_IDORDRE = ORD_IDORDRE WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDORDRE = @v_ord_idordre
						AND EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE ATA_IDTACHE = TAC_IDTACHE
						AND ATA_IDTYPEACTION = @ACTION_PRIMAIRE AND ACT_IDACTION = ATA_IDACTION AND ACT_OCCUPATION = 1)
				-- La somme du nombre d'outils nécessaires à la réalisation de chaque ordre occupant l'outil ne peut excéder le nombre d'outils disponibles
				-- Pour ces mêmes tâches, la somme du nombre d'outils nécessaires à la réalisation de chaque ordre libérant l'outil ne peut excéder le nombre d'outils disponibles
				IF ((SELECT (SELECT SUM(CEILING(CONVERT(float, TAC_COUNT) / CONVERT(float, @v_emplacement_outil))) FROM (SELECT COUNT(*) TAC_COUNT FROM @v_tache GROUP BY TAC_SYSTEME, TAC_BASE) ORDRE) + CEILING(CONVERT(float, COUNT(*)) / CONVERT(float, @v_emplacement_outil)) FROM @v_ordre) <= @v_outil_disponible)
					AND (ISNULL((SELECT SUM(CEILING(CONVERT(float, TAC_COUNT) / CONVERT(float, @v_emplacement_outil))) FROM (SELECT COUNT(*) TAC_COUNT FROM TACHE D INNER JOIN @v_tache P ON P.TAC_IDMISSION = D.TAC_IDMISSION
					WHERE EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE ATA_IDTACHE = D.TAC_IDTACHE AND ATA_IDTYPEACTION = @ACTION_PRIMAIRE AND ACT_IDACTION = ATA_IDACTION AND ACT_OCCUPATION = -1)
					GROUP BY ISNULL(D.TAC_IDAFFINAGEADRSYS, D.TAC_IDADRSYS), ISNULL(D.TAC_IDAFFINAGEADRBASE, D.TAC_IDADRBASE)) ORDRE), 0) <= @v_outil_disponible)
				BEGIN
					-- L'AGV sera-t-il plein ?
					IF (SELECT COUNT(*) FROM @v_tache) < @v_emplacement_outil * (@v_outil_disponible - (SELECT CEILING(CONVERT(float, COUNT(*)) / CONVERT(float, @v_emplacement_outil)) FROM @v_ordre))
						SET @v_retour = @CODE_OUI
					ELSE
						SET @v_retour = @CODE_NON
				END
				ELSE
					SET @v_retour = @CODE_KO_INCOMPATIBLE
			END
			ELSE
				SET @v_retour = @CODE_OUI
		END
		ELSE
			SET @v_retour = @CODE_KO_INCOMPATIBLE
	END
	ELSE
		SET @v_retour = @CODE_KO_INCOMPATIBLE
	RETURN @v_retour

