#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tests unitaires pour la logique métier de DeepSeekTray
Version Python pour validation croisée et intégration continue (CI/CD)
"""

import unittest
from datetime import datetime, time

class TestDeepSeekTrayLogic(unittest.TestCase):
    """Tests de la logique de détection des tranches horaires"""

    def time_to_minutes(self, time_str: str) -> int:
        """Convertit une chaîne HH:MM en minutes depuis minuit"""
        h, m = map(int, time_str.split(':'))
        return h * 60 + m

    def is_valid_time_format(self, time_str: str) -> bool:
        """Valide le format HH:MM"""
        if len(time_str) != 5 or time_str[2] != ':':
            return False
        try:
            h, m = map(int, time_str.split(':'))
            return 0 <= h <= 23 and 0 <= m <= 59
        except ValueError:
            return False

    def is_weekday(self, day_of_week: int) -> bool:
        """Vérifie si c'est un jour ouvré (1=Lundi, 7=Dimanche)"""
        return 1 <= day_of_week <= 5

    def est_dans_tranche(self, jour_test: int, heure_test_minutes: int, 
                         jour_debut: int, heure_debut: int, 
                         jour_fin: int, heure_fin: int) -> bool:
        """
        Vérifie si un moment donné est dans une tranche horaire.
        jour_test: 1 (Lundi) à 7 (Dimanche)
        heure_test_minutes: minutes depuis minuit (0-1439)
        """
        # Cas simple : même jour
        if jour_debut == jour_fin:
            if jour_test == jour_debut:
                return heure_debut <= heure_test_minutes <= heure_fin
        
        # Cas chevauchement minuit
        else:
            # Si on est le jour de début et après l'heure de début
            if jour_test == jour_debut and heure_test_minutes >= heure_debut:
                return True
            
            # Si on est le jour de fin et avant l'heure de fin
            if jour_test == jour_fin and heure_test_minutes <= heure_fin:
                return True
            
            # Cas spécial : chevauchement Dimanche (7) -> Lundi (1)
            if jour_debut == 7 and jour_fin == 1:
                if (jour_test == 7 and heure_test_minutes >= heure_debut) or \
                   (jour_test == 1 and heure_test_minutes <= heure_fin):
                    return True
        
        return False

    # =========================================================================
    # Tests de validation de format
    # =========================================================================
    
    def test_valid_time_format(self):
        self.assertTrue(self.is_valid_time_format("09:30"))
        self.assertTrue(self.is_valid_time_format("23:59"))
        self.assertTrue(self.is_valid_time_format("00:00"))

    def test_invalid_time_format(self):
        self.assertFalse(self.is_valid_time_format("24:00"))
        self.assertFalse(self.is_valid_time_format("12:60"))
        self.assertFalse(self.is_valid_time_format("9:30"))  # Manque le 0
        self.assertFalse(self.is_valid_time_format("abcde"))
        self.assertFalse(self.is_valid_time_format(""))

    def test_time_to_minutes(self):
        self.assertEqual(self.time_to_minutes("00:00"), 0)
        self.assertEqual(self.time_to_minutes("01:30"), 90)
        self.assertEqual(self.time_to_minutes("23:59"), 1439)

    # =========================================================================
    # Tests des jours de la semaine
    # =========================================================================
    
    def test_weekday_detection(self):
        self.assertTrue(self.is_weekday(1))   # Lundi
        self.assertTrue(self.is_weekday(3))   # Mercredi
        self.assertTrue(self.is_weekday(5))   # Vendredi
        self.assertFalse(self.is_weekday(6))  # Samedi
        self.assertFalse(self.is_weekday(7))  # Dimanche

    # =========================================================================
    # Tests de la logique métier : Tranches horaires
    # =========================================================================
    
    def test_tranche_simple_meme_jour(self):
        """Test d'une tranche horaire simple sur un même jour"""
        debut = self.time_to_minutes("09:00")
        fin = self.time_to_minutes("17:00")
        
        # Lundi 10:00 (600 min) -> dans la tranche
        self.assertTrue(self.est_dans_tranche(1, 600, 1, debut, 1, fin))
        
        # Lundi 08:00 (480 min) -> hors tranche
        self.assertFalse(self.est_dans_tranche(1, 480, 1, debut, 1, fin))
        
        # Lundi 18:00 (1080 min) -> hors tranche
        self.assertFalse(self.est_dans_tranche(1, 1080, 1, debut, 1, fin))
        
        # Mardi 10:00 -> hors tranche (mauvais jour)
        self.assertFalse(self.est_dans_tranche(2, 600, 1, debut, 1, fin))

    def test_tranche_chevauchement_minuit(self):
        """Test d'une tranche qui chevauche minuit (ex: 22:00 -> 02:00)"""
        debut = self.time_to_minutes("22:00")  # 1320
        fin = self.time_to_minutes("02:00")    # 120
        
        # Vendredi 23:00 (1380 min) -> dans la tranche
        self.assertTrue(self.est_dans_tranche(5, 1380, 5, debut, 6, fin))
        
        # Samedi 01:00 (60 min) -> dans la tranche
        self.assertTrue(self.est_dans_tranche(6, 60, 5, debut, 6, fin))
        
        # Vendredi 21:00 (1260 min) -> hors tranche
        self.assertFalse(self.est_dans_tranche(5, 1260, 5, debut, 6, fin))
        
        # Samedi 03:00 (180 min) -> hors tranche
        self.assertFalse(self.est_dans_tranche(6, 180, 5, debut, 6, fin))
        
        # Jeudi 23:00 -> hors tranche (mauvais jour)
        self.assertFalse(self.est_dans_tranche(4, 1380, 5, debut, 6, fin))

    def test_tranche_dimanche_lundi(self):
        """Test du cas spécial Dimanche (7) -> Lundi (1)"""
        debut = self.time_to_minutes("22:00")  # 1320
        fin = self.time_to_minutes("02:00")    # 120
        
        # Dimanche 23:00 (1380 min) -> dans la tranche
        self.assertTrue(self.est_dans_tranche(7, 1380, 7, debut, 1, fin))
        
        # Lundi 01:00 (60 min) -> dans la tranche
        self.assertTrue(self.est_dans_tranche(1, 60, 7, debut, 1, fin))
        
        # Samedi 23:00 -> hors tranche
        self.assertFalse(self.est_dans_tranche(6, 1380, 7, debut, 1, fin))

if __name__ == '__main__':
    # Exécution des tests avec verbosité
    unittest.main(verbosity=2)
