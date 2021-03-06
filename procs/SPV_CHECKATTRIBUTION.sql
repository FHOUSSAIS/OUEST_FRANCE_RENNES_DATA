SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_CHECKATTRIBUTION
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant de l'AGV
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : L'attribution peut être exécutée
--			    - @CODE_KO : L'attribution ne peut pas être exécutée
-- Descriptif		: Vérification de la possibilité d'exécution de l'attribution
--			  pour un AGV.
--			  Une attribution peut être exécutée si :
--			    - il n'existe pas de mission programmée (en attente) pour l'AGV,
--			    dont la 1ère adresse est distante de sa base de destination (uniquement pour les AGV de type Convoyeur)
--			    - l'AGV ne réalise pas une mission de type batterie, maintenance
--			    - il n'existe pas d'ordre en attente dont la description indique
--			    qu'il a été envoyé
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_CHECKATTRIBUTION]
	@v_iag_idagv tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_retour smallint,
	@v_tag_type_outil tinyint
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_ANNULE tinyint,
	@ETAT_TERMINE tinyint,
	@DESC_ENVOYE tinyint

--Déclaration des constantes de type de missions
DECLARE
	@TYPE_BATTERIE tinyint,
	@TYPE_MOUVEMENT tinyint,
	@TYPE_MAINTENANCE tinyint
	
-- Déclaration des constantes de mode d'exploitation
DECLARE
	@MODE_TEST int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_ENVOYE = 13
	SET @TYPE_BATTERIE = 2
	SET @TYPE_MOUVEMENT = 3
	SET @TYPE_MAINTENANCE = 4
	SET @MODE_TEST = 1

-- Initialisation de la variable de retour
	SET @v_retour = @CODE_OK

	IF EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_MODE_EXPLOIT <> @MODE_TEST)
	BEGIN
		SELECT @v_tag_type_outil = TAG_TYPE_OUTIL FROM INFO_AGV, TYPE_AGV WHERE IAG_ID = @v_iag_idagv AND TAG_ID = IAG_TYPE
		IF @v_tag_type_outil = 0 AND EXISTS (SELECT 1 FROM TACHE JOIN ORDRE_AGV ON TAC_IDORDRE = ORD_IDORDRE
			AND ORD_IDETAT NOT IN (@ETAT_ANNULE, @ETAT_TERMINE) WHERE ORD_IDAGV = @v_iag_idagv AND TAC_IDETAT = @ETAT_ENATTENTE
			AND TAC_POSITION_TACHE = 1 AND TAC_IDADRBASE <> (SELECT IAG_BASE_DEST FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv))
			OR EXISTS ((SELECT 1 FROM MISSION WHERE MIS_IDAGV = @v_iag_idagv
			AND ((MIS_TYPEMISSION IN (@TYPE_BATTERIE, @TYPE_MAINTENANCE)
			AND ((MIS_IDETAT = @ETAT_ENCOURS) OR EXISTS (SELECT 1 FROM TACHE INNER JOIN ORDRE_AGV ON ORD_IDORDRE = TAC_IDORDRE WHERE TAC_IDMISSION = MIS_IDMISSION)))
			OR (MIS_TYPEMISSION = @TYPE_MOUVEMENT AND MIS_IDETAT = @ETAT_ENATTENTE)))
			UNION (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv
			AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE))
			SET @v_retour = @CODE_KO
	END

	RETURN @v_retour

